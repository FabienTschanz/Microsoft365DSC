using Microsoft365DSC.Utilities;
using System;
using System.Collections;
using System.Collections.Generic;
using System.Linq;

namespace Microsoft365DSC.Compare
{
    /// <summary>
    /// Random access over a deserialized SchemaDefinition.json, so a comparison of two whole
    /// configurations does not rescan the schema array once per resource instance.
    /// </summary>
    internal sealed class SchemaIndex
    {
        private readonly Dictionary<string, object> _byClassName = new(StringComparer.OrdinalIgnoreCase);
        private readonly Dictionary<string, MandatoryParameters> _mandatory = new(StringComparer.OrdinalIgnoreCase);
        private readonly Dictionary<string, string[]> _keys = new(StringComparer.OrdinalIgnoreCase);

        /// <summary>
        /// The schema as handed in, for the calls that scan it themselves.
        /// </summary>
        public IEnumerable<object> Schema { get; }

        private SchemaIndex(IEnumerable<object> schema)
        {
            Schema = schema;

            foreach (object entry in schema)
            {
                string? className = MemberAccessor.GetMemberAsString(entry, "ClassName");
                if (!string.IsNullOrEmpty(className) && !_byClassName.ContainsKey(className!))
                {
                    _byClassName[className!] = entry;
                }
            }
        }

        public static SchemaIndex Create(IEnumerable<object> schema)
        {
            return schema is null ? throw new ArgumentNullException(nameof(schema)) : new SchemaIndex(schema);
        }

        /// <summary>
        /// The names of the parameters a resource declares as Key or Required, in schema order.
        /// Empty when the resource is not in the schema.
        /// </summary>
        public MandatoryParameters GetMandatory(string resourceName)
        {
            if (_mandatory.TryGetValue(resourceName, out MandatoryParameters cached))
            {
                return cached;
            }

            List<string> names = [];

            if (_byClassName.TryGetValue("MSFT_" + resourceName, out object? definition) &&
                MemberAccessor.TryGetMember(definition, "Parameters", out object? parameters))
            {
                foreach (object parameter in AsSequence(parameters))
                {
                    string? option = MemberAccessor.GetMemberAsString(parameter, "Option");
                    if (!string.Equals(option, "Key", StringComparison.OrdinalIgnoreCase) &&
                        !string.Equals(option, "Required", StringComparison.OrdinalIgnoreCase))
                    {
                        continue;
                    }

                    string? name = MemberAccessor.GetMemberAsString(parameter, "Name");
                    if (!string.IsNullOrEmpty(name))
                    {
                        names.Add(name!);
                    }
                }
            }

            MandatoryParameters result = new(names);
            _mandatory[resourceName] = result;
            return result;
        }

        /// <summary>
        /// The key property names resolved for a resource, computed once per comparison.
        /// </summary>
        /// <remarks>
        /// The first instance of a resource decides the key for every later instance of it. Two
        /// instances of the same resource must be keyed the same way or they cannot be paired
        /// against a single destination lookup.
        /// </remarks>
        public string[] GetKeys(string resourceName, Func<string[]> resolve)
        {
            if (!_keys.TryGetValue(resourceName, out string[] keys))
            {
                keys = resolve();
                _keys[resourceName] = keys;
            }

            return keys;
        }

        /// <summary>
        /// The compare parameters a resource declares in the schema, or null when it declares none.
        /// </summary>
        public ResourceCompareParameters? GetCompareParameters(string resourceName)
        {
            if (!_byClassName.TryGetValue("MSFT_" + resourceName, out object? definition) ||
                !MemberAccessor.TryGetMember(definition, "CompareParameters", out object? declared) ||
                declared is null)
            {
                return null;
            }

            return new ResourceCompareParameters
            {
                ExcludedProperties = AsStrings(declared, "ExcludedProperties"),
                IncludedProperties = AsStrings(declared, "IncludedProperties")
            };
        }

        private static string[]? AsStrings(object source, string name)
        {
            if (!MemberAccessor.TryGetMember(source, name, out object? value) || value is null)
            {
                return null;
            }

            List<string> result = [];
            foreach (object item in AsSequence(value))
            {
                if (item is not null)
                {
                    result.Add(item.ToString());
                }
            }

            return result.Count == 0 ? null : [.. result];
        }

        private static IEnumerable<object> AsSequence(object? value)
        {
            return value switch
            {
                null => [],
                string => [],
                IEnumerable<object> typed => typed,
                IEnumerable sequence => sequence.Cast<object>(),
                _ => [value]
            };
        }
    }

    /// <summary>
    /// The Key and Required parameters of one resource, with membership lookup.
    /// </summary>
    internal readonly struct MandatoryParameters(List<string> names)
    {
        private readonly HashSet<string> _lookup = new(names, StringComparer.OrdinalIgnoreCase);

        public List<string> Names { get; } = names;

        public int Count => Names.Count;

        public bool Contains(string name) => _lookup.Contains(name);
    }
}
