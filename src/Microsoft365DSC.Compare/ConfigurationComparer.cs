using Microsoft365DSC.Utilities;
using System;
using System.Collections;
using System.Collections.Generic;
using System.Linq;

namespace Microsoft365DSC.Compare
{
    /// <summary>
    /// Compares two whole configurations by pairing their resource instances by key, diffs each pair
    /// with <see cref="ResourceComparer"/>, and reports instances that exist on only one side.
    /// </summary>
    public static class ConfigurationComparer
    {
        /// <summary>
        /// Marks a resource that is not present on both sides, as opposed to a property that differs.
        /// </summary>
        public const string PresenceMarker = "_IsInConfiguration_";

        private static readonly string[] AlwaysExcludedProperties =
        [
            "ResourceInstanceName", "Credential", "ManagedIdentity", "ApplicationId", "TenantId",
            "CertificatePath", "CertificatePassword", "CertificateThumbprint", "ApplicationSecret"
        ];

        /// <summary>
        /// Compares a source configuration against a destination configuration.
        /// </summary>
        /// <param name="source">Parsed resources of the source, each a hashtable carrying ResourceName.</param>
        /// <param name="destination">Parsed resources of the destination, in the same shape.</param>
        /// <param name="schema">The deserialized SchemaDefinition.json.</param>
        /// <param name="excludedProperties">Property names to skip on every resource.</param>
        /// <param name="excludedResources">Resource names to skip entirely.</param>
        /// <param name="compareParameters">
        /// Per-resource comparison overrides, keyed by resource name. Merged with the schema's own
        /// declarations, and the only way to supply a post-processing callback, which cannot be
        /// expressed in the schema.
        /// </param>
        /// <returns>One entry per differing property, plus one per resource missing on either side.</returns>
        public static List<ConfigurationDelta> Compare(
            IEnumerable<object> source,
            IEnumerable<object> destination,
            IEnumerable<object> schema,
            string[]? excludedProperties = null,
            string[]? excludedResources = null,
            IDictionary<string, ResourceCompareParameters>? compareParameters = null)
        {
            if (source is null)
                throw new ArgumentNullException(nameof(source));
            if (destination is null)
                throw new ArgumentNullException(nameof(destination));
            if (schema is null)
                throw new ArgumentNullException(nameof(schema));

            SchemaIndex index = SchemaIndex.Create(schema);

            var excludedResourceSet = new HashSet<string>(
                excludedResources ?? [], StringComparer.OrdinalIgnoreCase);

            string[] globalExclusions = [.. AlwaysExcludedProperties.Concat(excludedProperties ?? []).Distinct(StringComparer.OrdinalIgnoreCase)];

            List<Hashtable> sourceResources = Materialize(source, excludedResourceSet);
            List<Hashtable> destinationResources = Materialize(destination, excludedResourceSet);

            List<ConfigurationDelta> delta = [];

            foreach (Hashtable resource in sourceResources)
            {
                string resourceName = resource["ResourceName"]?.ToString() ?? string.Empty;
                string[] keys = ResourceKeyResolver.Resolve(resource, index);

                Hashtable? match = FindCounterpart(destinationResources, resource, resourceName, keys);
                string keyName = KeyName(keys);
                string keyValue = KeyValue(resource, keys);

                if (match is null)
                {
                    delta.Add(Presence(resource, keyName, keyValue, inSource: "Present", inDestination: "Absent"));
                    continue;
                }

                AddPropertyDeltas(delta, resource, match, resourceName, keyName, keyValue, index, globalExclusions, compareParameters);
            }

            foreach (Hashtable resource in destinationResources)
            {
                string resourceName = resource["ResourceName"]?.ToString() ?? string.Empty;
                string[] keys = ResourceKeyResolver.Resolve(resource, index);

                if (FindCounterpart(sourceResources, resource, resourceName, keys) is null)
                {
                    delta.Add(Presence(resource, KeyName(keys), KeyValue(resource, keys), inSource: "Absent", inDestination: "Present"));
                }
            }

            return delta;
        }

        private static void AddPropertyDeltas(
            List<ConfigurationDelta> delta,
            Hashtable source,
            Hashtable destination,
            string resourceName,
            string keyName,
            string keyValue,
            SchemaIndex index,
            string[] globalExclusions,
            IDictionary<string, ResourceCompareParameters>? compareParameters)
        {
            ResourceCompareParameters? overrides = Overrides(resourceName, index, compareParameters);

            string[] excluded = overrides?.ExcludedProperties is { Length: > 0 } resourceExclusions
                ? [.. globalExclusions.Concat(resourceExclusions).Distinct(StringComparer.OrdinalIgnoreCase)]
                : globalExclusions;

            Hashtable desiredValues = destination;
            Hashtable currentValues = source;
            Hashtable valuesToCheck = (Hashtable)destination.Clone();

            if (overrides?.PostProcessing is { } postProcessing)
            {
                Tuple<Hashtable, Hashtable, Hashtable>? processed = postProcessing(
                    desiredValues, currentValues, valuesToCheck, overrides.PostProcessingArgs ?? []);

                if (processed is not null)
                {
                    desiredValues = processed.Item1;
                    currentValues = processed.Item2;
                    valuesToCheck = processed.Item3;
                }
            }

            CompareResult result = ResourceComparer.Compare(
                desiredValues,
                currentValues,
                valuesToCheck,
                index.Schema,
                resourceName,
                excluded,
                overrides?.IncludedProperties);

            if (result.TestResult)
            {
                return;
            }

            foreach (Hashtable drift in result.DriftInfo)
            {
                string propertyName = drift["PropertyName"]?.ToString() ?? string.Empty;

                ConfigurationDeltaProperty property = new()
                {
                    ParameterName = propertyName,
                    ValueInSource = drift["CurrentValue"],
                    ValueInDestination = drift["DesiredValue"],
                    DeltaValue = drift.ContainsKey("DeltaValue") ? drift["DeltaValue"] : null
                };

                ApplyAnnotation(property, destination, propertyName);

                delta.Add(new ConfigurationDelta
                {
                    ResourceName = resourceName,
                    ResourceInstanceName = source["ResourceInstanceName"]?.ToString(),
                    Key = keyName,
                    KeyValue = keyValue,
                    Properties = [property]
                });
            }
        }

        /// <summary>
        /// Copies a blueprint annotation onto the drift it explains. The comment travels with the
        /// destination resource as "_metadata_&lt;Property&gt;" holding "### Level|Information".
        /// </summary>
        private static void ApplyAnnotation(ConfigurationDeltaProperty property, Hashtable destination, string propertyName)
        {
            if (destination["_metadata_" + propertyName]?.ToString() is not { } annotation)
            {
                return;
            }

            string[] parts = annotation.Split('|');
            if (parts.Length < 2)
            {
                return;
            }

            property.MetadataLevel = parts[0].Replace("### ", string.Empty);
            property.MetadataInfo = parts[1];
        }

        private static ResourceCompareParameters? Overrides(
            string resourceName,
            SchemaIndex index,
            IDictionary<string, ResourceCompareParameters>? compareParameters)
        {
            if (compareParameters is not null && compareParameters.TryGetValue(resourceName, out ResourceCompareParameters? supplied))
            {
                return supplied;
            }

            return index.GetCompareParameters(resourceName);
        }

        /// <summary>
        /// Finds the instance of the same resource carrying the same key values, or null.
        /// </summary>
        private static Hashtable? FindCounterpart(
            List<Hashtable> candidates, Hashtable resource, string resourceName, string[] keys)
        {
            if (keys.Length == 0)
            {
                return null;
            }

            List<Hashtable> matches = Microsoft365DSC.Utilities.Utilities.FilterHashtablesByResourceAndKey(
                candidates, resourceName, keys[0], resource[keys[0]]?.ToString());

            for (int i = 1; i < keys.Length && matches.Count > 0; i++)
            {
                string? expected = resource[keys[i]]?.ToString();
                matches = [.. matches.Where(candidate => candidate[keys[i]]?.ToString() == expected)];
            }

            return matches.Count > 0 ? matches[0] : null;
        }

        private static ConfigurationDelta Presence(
            Hashtable resource, string keyName, string keyValue, string inSource, string inDestination)
        {
            return new ConfigurationDelta
            {
                ResourceName = resource["ResourceName"]?.ToString(),
                ResourceInstanceName = resource["ResourceInstanceName"]?.ToString(),
                Key = keyName,
                KeyValue = keyValue,
                Properties =
                [
                    new ConfigurationDeltaProperty
                    {
                        ParameterName = PresenceMarker,
                        ValueInSource = inSource,
                        ValueInDestination = inDestination
                    }
                ]
            };
        }

        private static List<Hashtable> Materialize(IEnumerable<object> resources, HashSet<string> excludedResources)
        {
            List<Hashtable> result = [];

            foreach (object entry in resources)
            {
                if (MemberAccessor.Unwrap(entry) is not Hashtable resource)
                {
                    continue;
                }

                if (resource["ResourceName"]?.ToString() is { } name && excludedResources.Contains(name))
                {
                    continue;
                }

                result.Add(resource);
            }

            return result;
        }

        // The first two keys, which is what the report shows as the identity of an instance.
        private static string KeyName(string[] keys) => string.Join("\\", keys.Take(2));

        private static string KeyValue(Hashtable resource, string[] keys) =>
            string.Join("\\", keys.Select(key => resource[key]?.ToString()));
    }

    /// <summary>
    /// One resource instance's difference between two configurations.
    /// </summary>
    public class ConfigurationDelta
    {
        public string? ResourceName { get; set; }

        public string? ResourceInstanceName { get; set; }

        /// <summary>The property names the instance is identified by, backslash separated.</summary>
        public string? Key { get; set; }

        public string? KeyValue { get; set; }

        public List<ConfigurationDeltaProperty> Properties { get; set; } = [];

        /// <summary>
        /// Projects the entry into the shape PowerShell callers render and serialize.
        /// </summary>
        public Hashtable ToHashtable()
        {
            return new Hashtable(StringComparer.OrdinalIgnoreCase)
            {
                { "ResourceName", ResourceName },
                { "ResourceInstanceName", ResourceInstanceName },
                { "Key", Key },
                { "KeyValue", KeyValue },
                { "Properties", Properties.Select(property => property.ToHashtable()).ToArray() }
            };
        }
    }

    /// <summary>
    /// One differing property, or the presence marker when the resource is missing on a side.
    /// </summary>
    public class ConfigurationDeltaProperty
    {
        public string? ParameterName { get; set; }

        public object? ValueInSource { get; set; }

        public object? ValueInDestination { get; set; }

        /// <summary>Set only for collection drifts, holding the added and removed entries.</summary>
        public object? DeltaValue { get; set; }

        /// <summary>Blueprint severity of the annotated property, when the destination carries one.</summary>
        public string? MetadataLevel { get; set; }

        public string? MetadataInfo { get; set; }

        public Hashtable ToHashtable()
        {
            Hashtable result = new(StringComparer.OrdinalIgnoreCase)
            {
                { "ParameterName", ParameterName },
                { "ValueInSource", ValueInSource },
                { "ValueInDestination", ValueInDestination }
            };

            if (DeltaValue is not null)
            {
                result["DeltaValue"] = DeltaValue;
            }

            if (MetadataLevel is not null)
            {
                result["_Metadata_Level"] = MetadataLevel;
                result["_Metadata_Info"] = MetadataInfo;
            }

            return result;
        }
    }

    /// <summary>
    /// Per-resource overrides of how its instances are compared.
    /// </summary>
    public class ResourceCompareParameters
    {
        public string[]? ExcludedProperties { get; set; }

        public string[]? IncludedProperties { get; set; }

        /// <summary>
        /// Rewrites desired, current and checked values before the diff. Supplied by the resource
        /// itself, so it exists only where a caller can run the resource's own code.
        /// </summary>
        public Func<Hashtable, Hashtable, Hashtable, object[], Tuple<Hashtable, Hashtable, Hashtable>>? PostProcessing { get; set; }

        public object[]? PostProcessingArgs { get; set; }
    }
}
