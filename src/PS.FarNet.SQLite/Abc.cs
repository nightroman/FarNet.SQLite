using System.Management.Automation;

namespace PS.FarNet.SQLite;

static class Abc
{
    public static object BaseObject(object value)
    {
        return value is PSObject ps ? ps.BaseObject : value;
    }
}
