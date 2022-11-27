// Tests different Execute* methods.

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
    db.Execute("insert into t1 (Id, Name) values (@Id, 'q2')", ("Id", box 2))
    db.Execute("insert into t1 (Id, Name) values (@Id, 'q2')", struct("Id", box 3))

    //// Execute, 2 parameters
    let prm = Dictionary()
    prm.Add("Id", box 4)
    prm.Add("Name", "q4")
    db.Execute("insert into t1 (Id, Name) values (@Id, @Name)", prm)
    db.Execute("insert into t1 (Id, Name) values (@Id, @Name)", ("Id", box 5), ("Name", "q5" :> obj))
    db.Execute("insert into t1 (Id, Name) values (@Id, @Name)", struct("Id", box 6), struct("Name", "q6" :> obj))

    // test
    let r = db.ExecuteScalar("select group_concat(Id || Name) from t1")
    test <@ r = "1q1,2q2,3q2,4q4,5q5,6q6" @>

    //// ExecuteScalar, no parameters
    let r = db.ExecuteScalar("select count() from t1")
    test <@ r = 6L @>

    //// ExecuteScalar, 1 parameter
    let prm = Dictionary()
    prm.Add("Id", box 4)
    let r = db.ExecuteScalar("select count() from t1 where Id < @Id", prm)
    test <@ r = 3L @>
    let r = db.ExecuteScalar("select count() from t1 where Id < @Id", ("Id", box 4))
    test <@ r = 3L @>
    let r = db.ExecuteScalar("select count() from t1 where Id < @Id", struct("Id", box 4))
    test <@ r = 3L @>

    //// ExecuteScalar, 2 parameters
    let prm = Dictionary()
    prm.Add("Id", box 4)
    prm.Add("Name", "q1")
    let r = db.ExecuteScalar("select count() from t1 where Id < @Id and Name > @Name", prm)
    test <@ r = 2L @>
    let r = db.ExecuteScalar("select count() from t1 where Id < @Id and Name > @Name", ("Id", box 4), ("Name", "q1" :> obj))
    test <@ r = 2L @>
    let r = db.ExecuteScalar("select count() from t1 where Id < @Id and Name > @Name", struct("Id", box 4), struct("Name", "q1" :> obj))
    test <@ r = 2L @>

    //// ExecuteTable, no parameters
    let r = db.ExecuteTable("select * from t1 where Id = 1 and Name = 'q1'")
    test <@ r.Rows[0]["Id"] = 1L && r.Rows[0]["Name"] = "q1" @>

    //// ExecuteTable, 1 parameter
    let prm = Dictionary()
    prm.Add("Id", box 1)
    let r = db.ExecuteTable("select * from t1 where Id = @Id and Name = 'q1'", prm)
    test <@ r.Rows[0]["Id"] = 1L && r.Rows[0]["Name"] = "q1" @>
    let r = db.ExecuteTable("select * from t1 where Id = @Id and Name = 'q1'", ("Id", box 1))
    test <@ r.Rows[0]["Id"] = 1L && r.Rows[0]["Name"] = "q1" @>
    let r = db.ExecuteTable("select * from t1 where Id = @Id and Name = 'q1'", struct("Id", box 1))
    test <@ r.Rows[0]["Id"] = 1L && r.Rows[0]["Name"] = "q1" @>

    //// ExecuteTable, 2 parameters
    let prm = Dictionary()
    prm.Add("Id", box 1)
    prm.Add("Name", "q1")
    let r = db.ExecuteTable("select * from t1 where Id = @Id and Name = 'q1'", prm)
    test <@ r.Rows[0]["Id"] = 1L && r.Rows[0]["Name"] = "q1" @>
    let r = db.ExecuteTable("select * from t1 where Id = @Id and Name = 'q1'", ("Id", box 1), ("Name", "q1" :> obj))
    test <@ r.Rows[0]["Id"] = 1L && r.Rows[0]["Name"] = "q1" @>
    let r = db.ExecuteTable("select * from t1 where Id = @Id and Name = 'q1'", struct("Id", box 1), struct("Name", "q1" :> obj))
    test <@ r.Rows[0]["Id"] = 1L && r.Rows[0]["Name"] = "q1" @>

    //// ExecuteNonQuery, no parameters
    let r = db.ExecuteNonQuery("delete from t1 where Id = 0")
    test <@ r = 0 @>

    //// ExecuteNonQuery, 1 parameter
    let prm = Dictionary()
    prm.Add("Id", 1)
    let r = db.ExecuteNonQuery("delete from t1 where Id = @Id", prm)
    test <@ r = 1 @>
    let r = db.ExecuteNonQuery("delete from t1 where Id = @Id", ("Id", box 2))
    test <@ r = 1 @>
    let r = db.ExecuteNonQuery("delete from t1 where Id = @Id", struct("Id", box 3))
    test <@ r = 1 @>

    //// ExecuteNonQuery, 2 parameters
    let prm = Dictionary()
    prm.Add("Id", box 4)
    prm.Add("Name", "q4")
    let r = db.ExecuteNonQuery("delete from t1 where Id = @Id and Name = @Name", prm)
    test <@ r = 1 @>
    let r = db.ExecuteNonQuery("delete from t1 where Id = @Id and Name = @Name", ("Id", box 5), ("Name", "q5" :> obj))
    test <@ r = 1 @>
    let r = db.ExecuteNonQuery("delete from t1 where Id = @Id and Name = @Name", struct("Id", box 6), struct("Name", "q6" :> obj))
    test <@ r = 1 @>

    // test
    let r = db.ExecuteScalar("select count() from t1")
    test <@ r = 0L @>
