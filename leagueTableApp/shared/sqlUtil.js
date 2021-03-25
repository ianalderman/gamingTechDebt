const { reject } = require("async");
const { request } = require("express");
const sql = require("mssql");
const { connect } = require("../app");
var connected = false;

sql.on('error', err => {
    console.error(err.message);
})

//valid auth types for env variable are defined here: http://tediousjs.github.io/tedious/api-connection.html, plan to use default and azure-active-directory-msi-app-service
const config = {
    authentication: {
        type: process.env.DB_AUTH_TYPE,
        options: {
            userName: process.env.DB_USER,
            password: process.env.DB_PASSWORD
        }
    },
    parseJSON: true,
    server: process.env.DB_SERVER,
    database: process.env.DB_NAME,
    options: {
        maxRetriesOnTransientErrors: 60,
        connectionRetryInterval: 1000,
        encrypt: true,
        appName: "leaderBoardApp"
    }
};

const connectionPool = new sql.ConnectionPool(config);

const openConnection = () => new Promise((resolve, reject) => {
    
    connectionPool.on('connect', err => {
        if (err) {
            reject(err);
        }
        else {
            connected = true;
            return true;
        }
    });   

    connectionPool.connect()

    //connected = true;
    //return true;
});

const executeStoredProc = async (procName, inputParameters, outputParameters) => {
    //return new Promise(function (resolve, reject) {
        let maxRetries = 5
        //https://stackoverflow.com/questions/38213668/promise-retry-design-patterns
        /*
        const wait = ms => new Promise(r => setTimeout(r, ms));

            const retryOperation = (operation, delay, retries) => new Promise((resolve, reject) => {
            return operation()
                .then(resolve)
                .catch((reason) => {
                if (retries > 0) {
                    return wait(delay)
                    .then(retryOperation.bind(null, operation, delay, retries - 1))
                    .then(resolve)
                    .catch(reject);
                }
                return reject(reason);
                });
            });
        */
        const wait = ms => new Promise(r => setTimeout(r, ms));

        const retryExecuteStoredProc = async (procedureName, inputParams, outputParams, retries) => new Promise((resolve, reject) => {
            sql.connect(config).then(pool => {
                let req = new sql.Request(pool)
                if (Array.isArray(inputParameters)) {
                    for (let i = 0; i < inputParameters.length; i++) {
                        req.input(i.name, i.type, i.value);
                    }
                }
                return req.execute(procName)
            }).then(result => {
                if ((result == "" || result == null || result == "null")) result = "[]";  
                resolve(result)
                //return result;
            }).catch((err) => {
                if (retries > 0) {
                    return wait(5000)
                    .then(retryExecuteStoredProc.bind(null,procedureName, inputParams, outputParams, retries - 1 ))
                    .then(resolve)
                    .catch(err) 
                }
                return reject(err)
            });
        });

        return retryExecuteStoredProc(procName, inputParameters, outputParameters, maxRetries)
}
        //});
    //});
    /*try {
        let pool = await sql.connect(config)

        let result2 = await pool.request()
            .execute(procName)
        return result2
    } catch (err) {
        console.error(err.message)
    }*/ 
//}



const executeJSONStoredProc = (procName, inputParameters) => {
    //we are not catering for output parameters in this function, we are also expecting all results as a JSON export
    //let request = new sql.Request()

    //if (connected == false) {
        //openConnection();
    //}
    let resultSet;

    sql.connect(config).then(pool => {
        let request = new sql.Request()
        //const request = new Request(procName)

        if (Array.isArray(inputParameters)) {
            for (let i = 0; i < inputParameters.length; i++) {
                request.input(i.name, i.type, i.value);
            }
        }
        return pool.request().execute(request)
        //pool.execute(request)
        //return request.execute(procName);            
    }).then(result => {
        request.on('recordset', columns => {
            columns.forEach(column => {
                resultSet += column.value;
            })
        })
    }).catch(err => {
        console.error(err.message);
    })

    //resolve(resultSet);
    

    //return request.execute(procName, (err, result) => {
    //    console.error("Error executing procedure:" + err.message);
   // })

    //return result;
}

exports.openConnection = openConnection;
exports.executeJSONStoredProc = executeJSONStoredProc;
exports.executeStoredProc = executeStoredProc;