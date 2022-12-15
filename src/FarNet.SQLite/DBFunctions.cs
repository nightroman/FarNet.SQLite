
using System.Data.SQLite;
using System.Text.RegularExpressions;

namespace FarNet.SQLite;

/// <summary>
/// Implements REGEXP.
/// </summary>
/// <remarks>
/// The result is false if any argument is not string.
/// </remarks>
[SQLiteFunction(Name = "REGEXP", Arguments = 2, FuncType = FunctionType.Scalar)]
public class RegexpSQLiteFunction : SQLiteFunction
{
    /// <summary>
    /// Implements REGEXP.
    /// </summary>
    public override object Invoke(object[] args)
    {
        if (args[0] is not string pattern || args[1] is not string input)
            return false;

        return Regex.IsMatch(input, pattern);
    }
}
