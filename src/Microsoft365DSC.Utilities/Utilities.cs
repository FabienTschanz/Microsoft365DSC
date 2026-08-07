using Microsoft365DSC.Cache;
using System;
using System.Collections;
using System.Collections.Generic;
using System.Linq;
using System.Management.Automation;
using System.Management.Automation.Language;

namespace Microsoft365DSC.Utilities
{
    public static class Utilities
    {
        /// <summary>
        /// Gets the names of the DSC properties declared by every class-based DSC resource in a module.
        /// </summary>
        /// <param name="modulePath">
        /// The path to the .psm1 file to parse. Both the generated Part<NN>.psm1 bundles and the
        /// per-resource source files are supported.
        /// </param>
        /// <returns>
        /// A dictionary keyed by class name, each value holding the names of the members that carry
        /// a DscProperty attribute. Classes without a DscResource attribute are not returned.
        /// </returns>
        public static Dictionary<string, List<string>> GetDscResourcePropertyNamesByAST(string modulePath)
        {
            ScriptBlockAst ast = Parser.ParseFile(modulePath, out _, out _);
            Dictionary<string, List<string>> resources = new(StringComparer.OrdinalIgnoreCase);

            foreach (TypeDefinitionAst typeDefinition in ast.FindAll(node => node is TypeDefinitionAst, searchNestedScriptBlocks: false).Cast<TypeDefinitionAst>())
            {
                if (typeDefinition.IsEnum ||
                    !HasAttribute(typeDefinition.Attributes, "DscResource") ||
                    resources.ContainsKey(typeDefinition.Name))
                {
                    continue;
                }

                resources[typeDefinition.Name] = typeDefinition.Members
                    .OfType<PropertyMemberAst>()
                    .Where(property => HasAttribute(property.Attributes, "DscProperty"))
                    .Select(property => property.Name)
                    .ToList();
            }

            return resources;
        }

        private static bool HasAttribute(IEnumerable<AttributeAst> attributes, string name)
        {
            return attributes.Any(attribute =>
                attribute.TypeName.Name.Equals(name, StringComparison.OrdinalIgnoreCase) ||
                attribute.TypeName.Name.Equals(name + "Attribute", StringComparison.OrdinalIgnoreCase));
        }

        /// <summary>
        /// Method to update special characters in strings.
        /// This method handles the conversion of special characters similar to Update-M365DSCSpecialCharacters.
        /// This function updates special characters in a string to be escaped in a DSC configuration.
        /// The function replaces the following characters:
        ///     - 0x201C = “
        ///     - 0x201D = ”
        ///     - 0x201E = „
        /// </summary>
        /// <param name="input">The input string to process</param>
        /// <returns>The processed string with special characters updated</returns>
        public static string UpdateSpecialCharacters(string input)
        {
            input = input.Replace(((char)0x201C).ToString(), "`" + ((char)0x201C).ToString());
            input = input.Replace(((char)0x201D).ToString(), "`" + ((char)0x201D).ToString());
            input = input.Replace(((char)0x201E).ToString(), "`" + ((char)0x201E).ToString());
            return input;
        }

        public static List<Hashtable> FilterHashtablesByResourceAndKey(IEnumerable<object> hashtables, string resourceName, string key, string keyValue)
        {
            List<Hashtable> results = [];
            foreach (Hashtable entry in hashtables.Cast<Hashtable>())
            {
                if (entry["ResourceName"].ToString() == resourceName &&
                    entry[key]?.ToString() == keyValue)
                {
                    results.Add(entry);
                }
            }
            return results;
        }

        public static object? FilterLoadedCimClassesByName(string className)
        {
            if (CacheManager.IsSchemaLoaded)
            {
                return FilterCimClassesByName(CacheManager.Schema, className);
            }
            return null;
        }

        public static object? FilterCimClassesByName(IEnumerable<object> schemaObjects, string className)
        {
            foreach (object obj in schemaObjects)
            {
                if (obj is PSObject psObject)
                {
                    dynamic dyn = psObject as dynamic;
                    string name = dyn.ClassName;
                    if (name == className)
                    {
                        return psObject;
                    }
                }
                else if (obj is IDictionary hashtable)
                {
                    if (hashtable["ClassName"]?.ToString() == className)
                    {
                        return hashtable;
                    }
                }
            }
            return null;
        }

        public static Array UnwrapArray(Array array)
        {
            for (int i = 0; i < array.Length; i++)
            {
                if (array.GetValue(i) is PSObject psObject)
                {
                    array.SetValue(psObject.BaseObject, i);
                }
            }
            return array;
        }

        public static List<string> UnwrapArrayToStrings(Array array)
        {
            List<string> results = [];
            foreach (object item in array)
            {
                object? innerItem = item;
                if (item is PSObject psObject)
                    innerItem = psObject.BaseObject;

                if (innerItem is string str)
                    results.Add(str);
                else
                    results.Add(innerItem.ToString());
            }
            return results;
        }
    }
}
