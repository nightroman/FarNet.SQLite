﻿
using System.Collections;

namespace System.Data.SQLite;

/// <summary>
/// SQLite helper for scripts and simple operations.
/// </summary>
public sealed class DB : IDisposable
{
    readonly SQLiteConnection _connection;

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
        _connection.Dispose();
    }

    /// <summary>
    /// Creates the connection.
    /// </summary>
    /// <include file='doc.xml' path='doc/DB/*'/>
    /// <remarks>
    /// If database and options are both omitted or empty then ":memory:" is used.
    /// Otherwise one of these parameters should specify the database.
    /// </remarks>
    public DB(string? database = null, string? options = null)
    {
        //! mind powershell may pass nulls as empty strings
        if (string.IsNullOrEmpty(database) && string.IsNullOrEmpty(options))
            database = ":memory:";

        var builder = new SQLiteConnectionStringBuilder(options);
        if (!string.IsNullOrEmpty(database))
            builder.DataSource = database;

        _connection = new SQLiteConnection(builder.ConnectionString);
        _connection.Open();
    }

    static void AddCommandParameters(SQLiteCommand command, object?[] parameters)
    {
        foreach (var obj in parameters)
        {
            if (obj is IDictionary dic)
            {
                foreach (DictionaryEntry it in dic)
                    command.Parameters.AddWithValue(it.Key.ToString(), it.Value);
                continue;
            }

            if (obj is SQLiteParameter prm)
            {
                command.Parameters.Add(prm);
                continue;
            }

            command.Parameters.AddWithValue((command.Parameters.Count + 1).ToString(), obj);
        }
    }

    /// <summary>
    /// Executes the non-query command.
    /// </summary>
    /// <include file='doc.xml' path='doc/Execute/*'/>
    public void Execute(string command, params object?[] parameters)
    {
        using var cmd = _connection.CreateCommand();
        cmd.CommandText = command;
        AddCommandParameters(cmd, parameters);
        cmd.ExecuteNonQuery();
    }

    /// <summary>
    /// Executes the non-query command and returns the number of affected records.
    /// </summary>
    /// <include file='doc.xml' path='doc/Execute/*'/>
    /// <returns>The number of affected records.</returns>
    public int ExecuteNonQuery(string command, params object?[] parameters)
    {
        using var cmd = _connection.CreateCommand();
        cmd.CommandText = command;
        AddCommandParameters(cmd, parameters);
        return cmd.ExecuteNonQuery();
    }

    /// <summary>
    /// Executes the query and returns the single value result.
    /// </summary>
    /// <include file='doc.xml' path='doc/Execute/*'/>
    /// <returns>The result value.</returns>
    public object ExecuteScalar(string command, params object?[] parameters)
    {
        using var cmd = _connection.CreateCommand();
        cmd.CommandText = command;
        AddCommandParameters(cmd, parameters);
        return cmd.ExecuteScalar();
    }

    /// <summary>
    /// Executes the query and returns the result data table.
    /// </summary>
    /// <include file='doc.xml' path='doc/Execute/*'/>
    /// <returns>The result data table.</returns>
    public DataTable ExecuteTable(string command, params object?[] parameters)
    {
        using var cmd = _connection.CreateCommand();
        cmd.CommandText = command;
        AddCommandParameters(cmd, parameters);

        using var adapter = new SQLiteDataAdapter(cmd);
        var table = new DataTable();
        adapter.Fill(table);

        return table;
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
