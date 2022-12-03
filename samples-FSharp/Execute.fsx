// Tests Execute* methods with IDictionary, SQLiteParameter, object parameters.

open System.Collections.Generic
open System.Text.Json
open System.Data.SQLite
open Swensen.Unquote

do
    use db = new DB()

    //// Execute, no parameters
    db.Execute("create table t1 (Id integer, Name text)")

    //// Execute, 1 parameter
    let prm = Dictionary()
    prm.Add("Id", 1)
    db.Execute("insert into t1 (Id, Name) values (@Id, 'q1')", prm)
    db.Execute("insert into t1 (Id, Name) values (@Id, 'q2')", SQLiteParameter("Id", 2))
    db.Execute("insert into t1 (Id, Name) values (?, 'q3')", 3)

    //// Execute, 2 parameters
    let prm = Dictionary()
    prm.Add("Id", box 4)
    prm.Add("Name", "q4")
    db.Execute("insert into t1 (Id, Name) values (@Id, @Name)", prm)
    db.Execute("insert into t1 (Id, Name) values (?1, ?2)", 5, "q5")

    // test
    let r = db.ExecuteScalar("select group_concat(Id || Name) from t1")
    test <@ r = "1q1,2q2,3q3,4q4,5q5" @>

    //// ExecuteScalar, no parameters
    let r = db.ExecuteScalar("select count() from t1")
    test <@ r = 5L @>

    //// ExecuteScalar, 1 parameter
    let prm = Dictionary()
    prm.Add("Id", 4)
    let r = db.ExecuteScalar("select count() from t1 where Id < @Id", prm)
    test <@ r = 3L @>
    let r = db.ExecuteScalar("select count() from t1 where Id < ?", 4)
    test <@ r = 3L @>

    //// ExecuteScalar, 2 parameters
    let prm = Dictionary()
    prm.Add("Id", box 4)
    prm.Add("Name", "q1")
    let r = db.ExecuteScalar("select count() from t1 where Id < @Id and Name > @Name", prm)
    test <@ r = 2L @>
    let r = db.ExecuteScalar("select count() from t1 where Id < ?1 and Name > ?2", 4, "q1")
    test <@ r = 2L @>

    //// ExecuteTable, no parameters
    let r = db.ExecuteTable("select * from t1 where Id = 1 and Name = 'q1'")
    test <@ r.Rows[0]["Id"] = 1L && r.Rows[0]["Name"] = "q1" @>

    //// ExecuteTable, 1 parameter
    let prm = Dictionary()
    prm.Add("Id", box 1)
    let r = db.ExecuteTable("select * from t1 where Id = @Id and Name = 'q1'", prm)
    test <@ r.Rows[0]["Id"] = 1L && r.Rows[0]["Name"] = "q1" @>
    let r = db.ExecuteTable("select * from t1 where Id = ? and Name = 'q1'", 1)
    test <@ r.Rows[0]["Id"] = 1L && r.Rows[0]["Name"] = "q1" @>

    //// ExecuteTable, 2 parameters
    let prm = Dictionary()
    prm.Add("Id", box 1)
    prm.Add("Name", "q1")
    let r = db.ExecuteTable("select * from t1 where Id = @Id and Name = 'q1'", prm)
    test <@ r.Rows[0]["Id"] = 1L && r.Rows[0]["Name"] = "q1" @>
    let r = db.ExecuteTable("select * from t1 where Id = ?1 and Name = ?2", 1, "q1")
    test <@ r.Rows[0]["Id"] = 1L && r.Rows[0]["Name"] = "q1" @>

    //// ExecuteColumn, no parameters
    let r = db.ExecuteColumn("select Id from t1")
    test <@ r = [|1L; 2L; 3L; 4L; 5L|] @>

    //// ExecuteColumn, 1 parameter
    let prm = Dictionary()
    prm.Add("Id", 4)
    let r = db.ExecuteColumn("select Id from t1 where Id < @Id", prm)
    test <@ r = [|1L; 2L; 3L|] @>
    let r = db.ExecuteColumn("select Id from t1 where Id < ?", 4)
    test <@ r = [|1L; 2L; 3L|] @>

    //// ExecuteColumn, 2 parameters
    let prm = Dictionary()
    prm.Add("Id", box 4)
    prm.Add("Name", "q1")
    let r = db.ExecuteColumn("select Id from t1 where Id < @Id and Name > @Name", prm)
    test <@ r = [|2L; 3L|] @>
    let r = db.ExecuteColumn("select Id from t1 where Id < ?1 and Name > ?2", 4, "q1")
    test <@ r = [|2L; 3L|] @>

    //// ExecuteLookup, no parameters
    let r = db.ExecuteLookup("select Name, Id from t1")
    test <@ r.Count = 5 && r["q3"] = 3L @>

    //// ExecuteLookup, 1 parameter
    let prm = Dictionary()
    prm.Add("Id", 4)
    let r = db.ExecuteLookup("select Name, Id from t1 where Id < @Id", prm)
    test <@ r.Count = 3 && r["q2"] = 2L @>
    let r = db.ExecuteLookup("select Name, Id from t1 where Id < ?", 4)
    test <@ r.Count = 3 && r["q2"] = 2L @>

    //// ExecuteLookup, 2 parameters
    let prm = Dictionary()
    prm.Add("Id", box 4)
    prm.Add("Name", "q1")
    let r = db.ExecuteLookup("select Name, Id from t1 where Id < @Id and Name > @Name", prm)
    test <@ r.Count = 2 && r["q2"] = 2L @>
    let r = db.ExecuteLookup("select Name, Id from t1 where Id < ?1 and Name > ?2", 4, "q1")
    test <@ r.Count = 2 && r["q2"] = 2L @>

    //// ExecuteNonQuery, no parameters
    let r = db.ExecuteNonQuery("delete from t1 where Id = 0")
    test <@ r = 0 @>

    //// ExecuteNonQuery, 1 parameter
    let prm = Dictionary()
    prm.Add("Id", 1)
    let r = db.ExecuteNonQuery("delete from t1 where Id = @Id", prm)
    test <@ r = 1 @>
    let r = db.ExecuteNonQuery("delete from t1 where Id = @Id", SQLiteParameter("Id", 2))
    test <@ r = 1 @>
    let r = db.ExecuteNonQuery("delete from t1 where Id = ?", 3)
    test <@ r = 1 @>

    //// ExecuteNonQuery, 2 parameters
    let prm = Dictionary()
    prm.Add("Id", box 4)
    prm.Add("Name", "q4")
    let r = db.ExecuteNonQuery("delete from t1 where Id = @Id and Name = @Name", prm)
    test <@ r = 1 @>
    let r = db.ExecuteNonQuery("delete from t1 where Id = ?1 and Name = ?2", 5, "q5")
    test <@ r = 1 @>

    // test
    let r = db.ExecuteScalar("select count() from t1")
    test <@ r = 0L @>
