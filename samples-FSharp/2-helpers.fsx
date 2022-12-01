// This sample uses System.Data.SQLite.DB helpers.

open System.Collections.Generic
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
    use db = new DB()

    db.Execute(init)

    let dt = db.ExecuteTable("SELECT * FROM TestCategories")
    test <@ dt.Rows.Count = 2 @>
    test <@ dt.Rows[0]["CategoryId"] = 1L @>
    test <@ dt.Rows[0]["Category"] = "Task" @>

    let res = db.ExecuteNonQuery("DELETE FROM TestCategories WHERE CategoryId = ?", 1)
    test <@ res = 1 @>

    let res = db.ExecuteScalar("SELECT count() FROM TestCategories")
    test <@ res = 1L @>
