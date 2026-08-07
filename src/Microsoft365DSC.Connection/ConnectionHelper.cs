using System;
using System.Collections;
using System.Collections.Generic;
using System.IO;

namespace Microsoft365DSC.Connection
{
    /// <summary>
    /// Provides methods for determining the most secure authentication type
    /// supported by Microsoft365DSC resources.
    /// </summary>
    public static class ConnectionHelper
    {
        /// <summary>
        /// Gets all resources that support the specified authentication method and
        /// determines the most secure authentication method supported by each resource.
        /// </summary>
        /// <param name="resourceModulesPath">
        /// The path to the folder containing the class-based resource modules. Both the generated
        /// Classes folder and the per-resource DscResources folder are supported.
        /// </param>
        /// <param name="authenticationMethods">
        /// The authentication methods to evaluate, in order of preference:
        /// ApplicationWithSecret, CertificateThumbprint, CertificatePath, Credentials,
        /// CredentialsWithTenantId, CredentialsWithApplicationId, ManagedIdentity, AccessTokens.
        /// </param>
        /// <param name="resources">
        /// The resource names to evaluate (without MSFT_ prefix).
        /// </param>
        /// <returns>
        /// A list of Hashtable objects, each containing 'Resource' (string) and 'AuthMethod' (string).
        /// </returns>
        public static List<Hashtable> GetComponentsWithMostSecureAuthenticationType(
            string resourceModulesPath,
            string[] authenticationMethods,
            string[] resources)
        {
            if (string.IsNullOrEmpty(resourceModulesPath))
            {
                throw new ArgumentNullException(nameof(resourceModulesPath));
            }

            if (authenticationMethods == null || authenticationMethods.Length == 0)
            {
                throw new ArgumentNullException(nameof(authenticationMethods));
            }

            if (resources == null || resources.Length == 0)
            {
                throw new ArgumentNullException(nameof(resources));
            }

            if (!Directory.Exists(resourceModulesPath))
            {
                throw new DirectoryNotFoundException($"The resource modules folder '{resourceModulesPath}' does not exist.");
            }

            HashSet<string>? resourceSet = new(resources, StringComparer.OrdinalIgnoreCase);
            HashSet<string>? authMethodSet = new(authenticationMethods, StringComparer.OrdinalIgnoreCase);
            List<Hashtable>? components = [];

            string[]? modules = Directory.GetFiles(resourceModulesPath, "*.psm1", SearchOption.AllDirectories);

            foreach (string modulePath in modules)
            {
                foreach (KeyValuePair<string, List<string>> resourceClass in Utilities.Utilities.GetDscResourcePropertyNamesByAST(modulePath))
                {
                    string resourceName = StripPrefix(resourceClass.Key, "MSFT_");

                    if (!resourceSet.Contains(resourceName))
                    {
                        continue;
                    }

                    HashSet<string>? propertySet = new(resourceClass.Value, StringComparer.OrdinalIgnoreCase);
                    string? authMethod = DetermineMostSecureAuthMethod(authMethodSet, propertySet, resourceName);

                    if (authMethod != null)
                    {
                        components.Add(new Hashtable
                        {
                            { "Resource", resourceName },
                            { "AuthMethod", authMethod }
                        });
                    }
                }
            }

            return components;
        }

        /// <summary>
        /// One authentication method a resource may support, and what it takes to qualify.
        /// </summary>
        private sealed class AuthenticationCandidate
        {
            public AuthenticationCandidate(
                string method,
                string authMethod,
                string[] requiredProperties,
                string[]? excludedResourcePrefixes = null)
            {
                Method = method;
                AuthMethod = authMethod;
                RequiredProperties = requiredProperties;
                ExcludedResourcePrefixes = excludedResourcePrefixes;
            }

            /// <summary>The method name as supplied by the caller.</summary>
            public string Method { get; }

            /// <summary>The name reported back for this method.</summary>
            public string AuthMethod { get; }

            /// <summary>Properties the resource must declare for this method to apply.</summary>
            public string[] RequiredProperties { get; }

            /// <summary>Resource name prefixes this method never applies to.</summary>
            public string[]? ExcludedResourcePrefixes { get; }
        }

        /// <summary>
        /// The authentication methods in descending order of security. The first candidate whose
        /// method was requested and whose properties the resource declares wins.
        /// </summary>
        private static readonly AuthenticationCandidate[] AuthenticationPriority =
        [
            new("CertificateThumbprint", "CertificateThumbprint", ["ApplicationId", "CertificateThumbprint", "TenantId"]),
            new("CertificatePath", "CertificatePath", ["ApplicationId", "CertificatePath", "TenantId"]),
            new("ApplicationWithSecret", "ApplicationSecret", ["ApplicationId", "ApplicationSecret", "TenantId"]),
            new("CredentialsWithTenantId", "CredentialsWithTenantId", ["Credential", "TenantId"], ["SPO", "OD", "PP"]),
            new("CredentialsWithApplicationId", "CredentialsWithApplicationId", ["Credential"]),
            new("Credentials", "Credentials", ["Credential"]),
            new("ManagedIdentity", "ManagedIdentity", ["ManagedIdentity"]),
            new("AccessTokens", "AccessTokens", ["AccessTokens"])
        ];

        /// <summary>
        /// Determines the most secure authentication method for a resource based on
        /// the authentication methods requested and the DSC properties the resource declares.
        /// </summary>
        private static string? DetermineMostSecureAuthMethod(
            HashSet<string> authMethods,
            HashSet<string> parameters,
            string resourceName)
        {
            foreach (AuthenticationCandidate candidate in AuthenticationPriority)
            {
                if (!authMethods.Contains(candidate.Method) ||
                    IsExcluded(resourceName, candidate.ExcludedResourcePrefixes) ||
                    !DeclaresAll(parameters, candidate.RequiredProperties))
                {
                    continue;
                }

                return candidate.AuthMethod;
            }

            return null;
        }

        private static bool IsExcluded(string resourceName, string[]? excludedPrefixes)
        {
            if (excludedPrefixes is null)
            {
                return false;
            }

            foreach (string prefix in excludedPrefixes)
            {
                if (resourceName.StartsWith(prefix, StringComparison.OrdinalIgnoreCase))
                {
                    return true;
                }
            }

            return false;
        }

        private static bool DeclaresAll(HashSet<string> parameters, string[] requiredProperties)
        {
            foreach (string required in requiredProperties)
            {
                if (!parameters.Contains(required))
                {
                    return false;
                }
            }

            return true;
        }

        private static string StripPrefix(string value, string prefix)
        {
            return value.StartsWith(prefix, StringComparison.OrdinalIgnoreCase)
                ? value.Substring(prefix.Length)
                : value;
        }
    }
}
