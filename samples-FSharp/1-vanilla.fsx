// This sample uses System.Data.SQLite without helpers.

open System.Data.SQLite
open Swensen.Unquote

let init = """
CREATE TABLE [TestCategories]
(
    [CategoryId] INTEGER PRIMARY KEY,
    [Category] TEXT NOT NULL,
    [Remarks] TEXT NULL
);
INSERT INTO TestCategories (Category, Remarks) VALUES ('Task', 'Task remarks');
INSERT INTO TestCategories (Category, Remarks) VALUES ('Warning', 'Warning remarks');
"""

do
    use db = new SQLiteConnection()
    db.ConnectionString <- "data source=:memory:"
    db.Open()

    do
        use cmd = db.CreateCommand()
        cmd.CommandText <- init
        cmd.ExecuteNonQuery() |> ignore

    do
        use cmd = db.CreateCommand()
        cmd.CommandText <- "SELECT * FROM TestCategories"
        use read = cmd.ExecuteReader()

        test <@ read.Read() @>
        test <@ read.GetInt32(0) = 1 @>
        test <@ read.GetString(1) = "Task" @>

        test <@ read.Read() @>
        test <@ read.GetInt32(0) = 2 @>
        test <@ read.GetString(1) = "Warning" @>

        test <@ read.Read() = false @>

    do
        use cmd = db.CreateCommand()
        cmd.CommandText <- "DELETE FROM TestCategories WHERE CategoryId = @id"
        cmd.Parameters.AddWithValue("id", 1) |> ignore
        test <@ cmd.ExecuteNonQuery() = 1 @>

    do
        use cmd = db.CreateCommand()
        cmd.CommandText <- "SELECT count() FROM TestCategories"
        test <@ cmd.ExecuteScalar() = 1L @>
