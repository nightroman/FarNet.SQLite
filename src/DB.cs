
using System.Collections;
using System.Collections.Generic;

namespace System.Data.SQLite;

/// <summary>
/// SQLite helper for scripts and simple operations.
/// </summary>
public sealed class DB : IDisposable
{
    readonly SQLiteConnection _connection;
    LinkedList<IDisposable>? _garbage;
    SQLiteTransaction? _transaction;

    /// <summary>
    /// Gets the SQLite connection instance.
    /// </summary>
    public SQLiteConnection Connection => _connection;

    /// <summary>
    /// Gets the SQLite factory instance.
    /// </summary>
    public SQLiteFactory Factory => SQLiteFactory.Instance;

    /// <summary>
    /// Closes the connection.
    /// </summary>
    public void Dispose()
    {
        if (_transaction != null)
        {
            _transaction.Dispose();
            _transaction = null;
        }

        if (_garbage != null)
        {
            foreach (var it in _garbage)
                it.Dispose();
            _garbage = null;
        }

        _connection.Dispose();
    }

    /// <summary>
    /// Commits the transaction created with the connection.
    /// </summary>
    public void Commit()
    {
        if (_transaction is null)
            throw new InvalidOperationException("There is no active transaction. It is either completed or not created.");

        try
        {
            _transaction.Commit();
        }
        finally
        {
            _transaction.Dispose();
            _transaction = null;
        }
    }

    /// <summary>
    /// Creates the connection.
    /// </summary>
    /// <include file='doc.xml' path='doc/DB/*'/>
    /// <remarks>
    /// If database and options are both omitted or empty then ":memory:" is used.
    /// Otherwise one of these parameters should specify the database.
    /// </remarks>
    public DB(string? database = null, string? options = null, bool beginTransaction = false)
    {
        //! mind powershell may pass nulls as empty strings
        if (string.IsNullOrEmpty(database) && string.IsNullOrEmpty(options))
            database = ":memory:";

        var builder = new SQLiteConnectionStringBuilder(options);
        if (!string.IsNullOrEmpty(database))
            builder.DataSource = database;

        _connection = new SQLiteConnection(builder.ConnectionString);
        _connection.Open();

        if (beginTransaction)
        {
            try
            {
                _transaction = _connection.BeginTransaction();
            }
            catch
            {
                _connection.Dispose();
            }
        }
    }

    private SQLiteCommand CreateCommandPrivate(string command, object?[] parameters)
    {
        var cmd = _connection.CreateCommand();
        cmd.CommandText = command;

        //! when null is passed as params
        if (parameters is null)
        {
            cmd.Parameters.AddWithValue("1", null);
            return cmd;
        }

        foreach (var obj in parameters)
        {
            if (obj is IDictionary dic)
            {
                foreach (DictionaryEntry it in dic)
                    cmd.Parameters.AddWithValue(it.Key.ToString(), it.Value);
                continue;
            }

            if (obj is SQLiteParameter prm)
            {
                cmd.Parameters.Add(prm);
                continue;
            }

            cmd.Parameters.AddWithValue((cmd.Parameters.Count + 1).ToString(), obj);
        }

        return cmd;
    }

    /// <summary>
    /// Creates a new command and optionally tells to dispose.
    /// </summary>
    /// <returns>The created command.</returns>
    /// <param name="command">The command text.</param>
    /// <param name="dispose">Tells to dispose on closing.</param>
    /// <param name="parameters">The command parameters.</param>
    public SQLiteCommand CreateCommand(string command, bool dispose, params SQLiteParameter[] parameters)
    {
        var cmd = _connection.CreateCommand();
        cmd.CommandText = command;
        if (parameters is not null)
            cmd.Parameters.AddRange(parameters);

        if (dispose)
        {
            _garbage ??= new();
            _garbage.AddFirst(cmd);
        }

        return cmd;
    }

    /// <summary>
    /// Creates a new command.
    /// </summary>
    /// <returns>The created command.</returns>
    /// <param name="command">The command text.</param>
    /// <param name="parameters">The command parameters.</param>
    public SQLiteCommand CreateCommand(string command, params SQLiteParameter[] parameters)
    {
        return CreateCommand(command, false, parameters);
    }

    /// <summary>
    /// Executes the non-query command.
    /// </summary>
    /// <param name="command">SQLiteCommand</param>
    public void Execute(SQLiteCommand command)
    {
        command.ExecuteNonQuery();
    }

    /// <summary>
    /// Executes the non-query command.
    /// </summary>
    /// <include file='doc.xml' path='doc/Execute/*'/>
    public void Execute(string command, params object?[] parameters)
    {
        using var cmd = CreateCommandPrivate(command, parameters);
        cmd.ExecuteNonQuery();
    }

    /// <summary>
    /// Executes the non-query command and returns the number of affected records.
    /// </summary>
    /// <returns>The number of affected records.</returns>
    /// <param name="command">SQLiteCommand</param>
    public int ExecuteNonQuery(SQLiteCommand command)
    {
        return command.ExecuteNonQuery();
    }

    /// <summary>
    /// Executes the non-query command and returns the number of affected records.
    /// </summary>
    /// <returns>The number of affected records.</returns>
    /// <include file='doc.xml' path='doc/Execute/*'/>
    public int ExecuteNonQuery(string command, params object?[] parameters)
    {
        using var cmd = CreateCommandPrivate(command, parameters);
        return cmd.ExecuteNonQuery();
    }

    /// <summary>
    /// Executes the query and returns the single value result.
    /// </summary>
    /// <returns>The result value.</returns>
    /// <param name="command">SQLiteCommand</param>
    public object ExecuteScalar(SQLiteCommand command)
    {
        return command.ExecuteScalar();
    }

    /// <summary>
    /// Executes the query and returns the single value result.
    /// </summary>
    /// <returns>The result value.</returns>
    /// <include file='doc.xml' path='doc/Execute/*'/>
    public object ExecuteScalar(string command, params object?[] parameters)
    {
        using var cmd = CreateCommandPrivate(command, parameters);
        return cmd.ExecuteScalar();
    }

    /// <summary>
    /// Executes the query and returns the result data table.
    /// </summary>
    /// <returns>The result data table.</returns>
    /// <param name="command">SQLiteCommand</param>
    public DataTable ExecuteTable(SQLiteCommand command)
    {
        using var adapter = new SQLiteDataAdapter(command);
        var table = new DataTable();
        adapter.Fill(table);
        return table;
    }

    /// <summary>
    /// Executes the query and returns the result data table.
    /// </summary>
    /// <returns>The result data table.</returns>
    /// <include file='doc.xml' path='doc/Execute/*'/>
    public DataTable ExecuteTable(string command, params object?[] parameters)
    {
        return ExecuteTable(CreateCommandPrivate(command, parameters));
    }

    /// <summary>
    /// Executes the query and returns the first column values.
    /// </summary>
    /// <returns>The result values array.</returns>
    /// <param name="command">SQLiteCommand</param>
    public object[] ExecuteColumn(SQLiteCommand command)
    {
        using var read = command.ExecuteReader();

        var list = new List<object>();
        while (read.Read())
            list.Add(read.GetValue(0));

        return list.ToArray();
    }

    /// <summary>
    /// Executes the query and returns the first column values.
    /// </summary>
    /// <returns>The result values array.</returns>
    /// <include file='doc.xml' path='doc/Execute/*'/>
    public object[] ExecuteColumn(string command, params object?[] parameters)
    {
        return ExecuteColumn(CreateCommandPrivate(command, parameters));
    }

    /// <summary>
    /// Executes the query and returns the first two column dictionary.
    /// </summary>
    /// <returns>The result dictionary.</returns>
    /// <param name="command">SQLiteCommand</param>
    public Dictionary<object, object> ExecuteLookup(SQLiteCommand command)
    {
        using var read = command.ExecuteReader();

        var dic = new Dictionary<object, object>();
        while (read.Read())
            dic.Add(read.GetValue(0), read.GetValue(1));

        return dic;
    }

    /// <summary>
    /// Executes the query and returns the first two column dictionary.
    /// </summary>
    /// <returns>The result dictionary.</returns>
    /// <include file='doc.xml' path='doc/Execute/*'/>
    public Dictionary<object, object> ExecuteLookup(string command, params object?[] parameters)
    {
        return ExecuteLookup(CreateCommandPrivate(command, parameters));
    }

    /// <summary>
    /// Invokes the action with a new transaction.
    /// </summary>
    /// <param name="action">The transaction action.</param>
    /// <remarks>
    /// Connect with <c>Flags=AllowNestedTransactions</c> for nested transactions.
    /// </remarks>
    public void UseTransaction(Action action)
    {
        using var transaction = _connection.BeginTransaction();
        action();
        transaction.Commit();
    }
}
