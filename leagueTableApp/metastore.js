var db = require("./shared/sqlUtil.js");
const groupDefinition = require("./shared/groupDefinition");
const { param } = require("./routes/index.js");

function setMetastoreGroupLevelDefinition(newGroupDefinition) {
    group = new groupDefinition()
    group.loadGroupDefinition(newGroupDefinition)

    return new Promise(function(resolve, reject) {
        db.executeStoredProc('setGroupDefinitions001', group.getSQLParameters()).then(result => (resolve(result))).catch(err => {
            reject(err)
        })
    })
}

async function getMetastoreGroupLevelDefinitions () {
    //check cache if not there query DB save to cache and then return value
    
    return new Promise(function(resolve, reject) {
        db.executeStoredProc('getGroupDefinitions001').then(result => (resolve(result))).catch(err => {
            reject(err)
        })
    })
}

exports.getMetastoreGroupLevelDefinitions = getMetastoreGroupLevelDefinitions
exports.setMetastoreGroupLevelDefinition = setMetastoreGroupLevelDefinition