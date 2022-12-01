// How to store as JSON 100%.

open System.Diagnostics
open System.Text.Json
open System.Data.SQLite
open Swensen.Unquote

let init = """
create table t1 (
    Id as (Value ->> '$.Id'),
    Name as (Value ->> '$.Name'),
    WorkingSet as (Value ->> '$.WorkingSet'),
    Value
);
create index t1_Id on t1(Id);
create index t1_Name on t1(Name);
"""

type Row = {
    Id: int
    Name: string
    WorkingSet: int64
    HandleCount: int
}

// get data to be saved
let rows =
    Process.GetProcesses()
    |> Array.map (fun x -> { Id = x.Id; Name = x.ProcessName; WorkingSet = x.WorkingSet64; HandleCount = x.HandleCount })

do
    // new database
    use db = new DB()
    db.Execute(init)

    // add data
    for row in rows do
        db.Execute(
            "insert into t1 (Value) values (?)",
            JsonSerializer.Serialize(row))

    // query (no JSON parsing here, SQLite uses the index for Id)
    let value = db.ExecuteScalar("select Value from t1 order by Id desc limit 1")

    // deserialise
    let row = JsonSerializer.Deserialize<Row>(string value);

    // show and test
    printfn $"{row}"
    test <@ row = (rows |> Array.sortByDescending (fun x -> x.Id))[0] @>
