var db = require("./shared/sqlUtil.js");
var redis = require("redis");
var path = require('path');

/*
if (process.env.NODE_ENV !== 'production') {
    require('dotenv').config({ path: path.resolve(process.cwd(), 'local.env')})
    var a = process.env.DB_AUTH_TYPE
  }
*/
//https://raw.githubusercontent.com/Azure-Samples/azure-sdk-for-js-keyvault-secrets-get-nodejs-managedid/master/v4/index.js
const KeyVaultSecret = require('@azure/keyvault-secrets');
const identity = require('@azure/identity');
const { filter } = require("async");



function getKeyVaultCredentials(){
    if (process.env.APPSETTING_WEBSITE_SITE_NAME){
      return msRestAzure.loginWithAppServiceMSI({resource: 'https://vault.azure.net'});
    } else {
        //need to store these in local.env
      return msRestAzure.loginWithServicePrincipalSecret(clientId, secret, domain);
    }
  }

//var connected = db.openConnection();

async function buildLeaderBoard() {
//const buildLeaderBoard = () => new Promise((resolve, reject) =>{
    //let gl1Values = await getGroupLevel1Values();
    //let gl2Values = await getGroupLevel2Values();
    
    let techDebtScores = await getTechDebtPointScores();
    let runSettings = await getRunSettings();
    runSettings = runSettings.recordset[0][0]

    //console.log(gl1Values)
    //var gl1ValObject = gl1Values.recordset[0];
   // console.log(gl1ValObject)
    
    var lboard = {}
    var gl1Entries = []
    
    lboard.Settings = runSettings

    //Pillars: Reliability, Security, Performance, Cost, Operational Excellence
    //now do we call gl2 for each gl1 or all gl2 and filter by gl1s as below?
    //Grouping | Reliability | Security | Performance | Cost | Operational Excellence | Budget | Total
    

    var distinctGl1List = [... new Set(techDebtScores.recordset[0].map(x => x.groupingLevel1))]
    var avariable = distinctGl1List.forEach (buildGroupingLevel1);

    function buildGroupingLevel1(item, index) {
        let gl1Entry = {}
        let gl2Entries = []

        let gl1Records = filterRecordSet(techDebtScores.recordset[0], "gl1", item)
        /*let gl1Records = techDebtScores.recordset[0].filter(function (objToFilter) {
            if (objToFilter.groupingLevel1 == item) {
                return true;
            } else {
                return false;
            }
        })*/

        gl1Entry.Name = item

        
        let gl1SecurityTotal = 0;
        let gl1ReliabilityTotal = 0;
        let gl1PerformanceTotal = 0
        let gl1CostTotal = 0
        let gl1OperationsTotal = 0
        let gl1PolicyTotal = 0
        let gl1HighSecurityCount = 0
        let gl1MediumSecurityCount = 0
        let gl1LowSecurityCount = 0
        let gl1Total = 0

        let distinctGl2List = [... new Set(gl1Records.map(x => x.groupingLevel2))]

        distinctGl2List.forEach(buildGroupingLevel2)

        function buildGroupingLevel2(item, index) {

            let gl2Records = filterRecordSet(gl1Records, "gl2", item)
            let gl2Entry = buildEntry(gl2Records, item)
           
            let productionRecords = filterRecordSet(gl2Records, "env", runSettings.EnvironmentProduction)

            let productionEntry = buildEntry(productionRecords, runSettings.EnvironmentProduction)

            let productionTier0Records = filterRecordSet(productionRecords, "tier", runSettings.CriticalityTier0)
            let productionTier0Entry = buildEntry(productionTier0Records, runSettings.CriticalityTier0)

            productionEntry.Tier0 = productionTier0Entry

            let productionTier1Records = filterRecordSet(productionRecords, "tier", runSettings.CriticalityTier1)
            let productionTier1Entry = buildEntry(productionTier1Records, runSettings.CriticalityTier1)

            productionEntry.Tier1 = productionTier1Entry

            let productionTier2Records = filterRecordSet(productionRecords, "tier", runSettings.CriticalityTier2)
            let productionTier2Entry = buildEntry(productionTier2Records, runSettings.CriticalityTier2)

            productionEntry.Tier2 = productionTier2Entry

            let productionUnknownTierRecords = filterRecordSet(productionRecords, "tier", "Unknown")
            let productionUnknownTierEntry = buildEntry(productionUnknownTierRecords, "Unknown")

            productionEntry.UnknownTier = productionUnknownTierEntry

            gl2Entry.Production = productionEntry

            let nonProductionRecords = filterRecordSet(gl2Records, "env", runSettings.EnvironmentNonProduction)
            let nonProductionEntry = buildEntry(nonProductionRecords, runSettings.EnvironmentNonProduction)

            let nonProductionTier0Records = filterRecordSet(nonProductionRecords, "tier", runSettings.CriticalityTier0)
            let nonProductionTier0Entry = buildEntry(nonProductionTier0Records, runSettings.CriticalityTier0)

            nonProductionEntry.Tier0 = nonProductionTier0Entry

            let nonProductionTier1Records = filterRecordSet(nonProductionRecords, "tier", runSettings.CriticalityTier1)
            let nonProductionTier1Entry = buildEntry(nonProductionTier1Records, runSettings.CriticalityTier1)

            nonProductionEntry.Tier1 = nonProductionTier1Entry

            let nonProductionTier2Records = filterRecordSet(nonProductionRecords, "tier", runSettings.CriticalityTier2)
            let nonProductionTier2Entry = buildEntry(nonProductionTier2Records, runSettings.CriticalityTier2)

            nonProductionEntry.Tier2 = nonProductionTier2Entry

            let nonProductionUnknownTierRecords = filterRecordSet(nonProductionRecords, "tier", "Unknown")
            let nonProductionUnknownTierEntry = buildEntry(nonProductionUnknownTierRecords, "Unknown")

            nonProductionEntry.UnknownTier = nonProductionUnknownTierEntry

            gl2Entry.nonProduction = nonProductionEntry

            let devRecords = filterRecordSet(gl2Records, "env", runSettings.EnvironmentDev)
            let devEntry = buildEntry(devRecords, runSettings.EnvironmentDev)

            let devTier0Records = filterRecordSet(devRecords, "tier", runSettings.CriticalityTier0)
            let devTier0Entry = buildEntry(devTier0Records, runSettings.CriticalityTier0)

            devEntry.Tier0 = devTier0Entry

            let devTier1Records = filterRecordSet(devRecords, "tier", runSettings.CriticalityTier1)
            let devTier1Entry = buildEntry(devTier1Records, runSettings.CriticalityTier1)

            devEntry.Tier1 = devTier1Entry

            let devTier2Records = filterRecordSet(devRecords, "tier", runSettings.CriticalityTier2)
            let devTier2Entry = buildEntry(devTier2Records, runSettings.CriticalityTier2)

            devEntry.Tier2 = devTier2Entry

            let devUnknownTierRecords = filterRecordSet(devRecords, "tier", "Unknown")
            let devUnknownTierEntry = buildEntry(devUnknownTierRecords, "Unknown")

            devEntry.UnknownTier = devUnknownTierEntry
            

            gl2Entry.dev = devEntry

            let unknownEnvironmentRecords = filterRecordSet(gl2Records, "env", "Unknown")
            let unknownEnvironmentEntry = buildEntry(unknownEnvironmentRecords, "Unknown")

            let unknownEnvironmentTier0Records = filterRecordSet(unknownEnvironmentRecords, "tier", runSettings.CriticalityTier0)
            let unknownEnvironmentTier0Entry = buildEntry(unknownEnvironmentTier0Records, runSettings.CriticalityTier0)

            unknownEnvironmentEntry.Tier0 = unknownEnvironmentTier0Entry

            let unknownEnvironmentTier1Records = filterRecordSet(unknownEnvironmentRecords, "tier", runSettings.CriticalityTier1)
            let unknownEnvironmentTier1Entry = buildEntry(unknownEnvironmentTier1Records, runSettings.CriticalityTier1)

            unknownEnvironmentEntry.Tier1 = unknownEnvironmentTier1Entry

            let unknownEnvironmentTier2Records = filterRecordSet(unknownEnvironmentRecords, "tier", runSettings.CriticalityTier2)
            let unknownEnvironmentTier2Entry = buildEntry(unknownEnvironmentTier2Records, runSettings.CriticalityTier2)

            unknownEnvironmentEntry.Tier2 = unknownEnvironmentTier2Entry

            let unknownEnvironmentUnknownTierRecords = filterRecordSet(unknownEnvironmentRecords, "tier", "Unknown")
            let unknownEnvironmentUnknownTierEntry = buildEntry(unknownEnvironmentUnknownTierRecords, "Unknown")

            unknownEnvironmentEntry.UnknownTier = unknownEnvironmentUnknownTierEntry

            gl2Entry.uknownEnvironment = unknownEnvironmentEntry

            gl2Entries.push(gl2Entry)

            gl1SecurityTotal += gl2Entry.Security.Points
            gl1ReliabilityTotal += gl2Entry.Reliability.Points
            gl1PerformanceTotal += gl2Entry.Performance.Points
            gl1OperationsTotal += gl2Entry.OperationalExcellence.Points
            gl1PolicyTotal += gl2Entry.Policy.Points
            gl1CostTotal += gl2Entry.Cost.Points
        }

        gl1Entry.groupingLevel2 = gl2Entries
        gl1Entry.Security = gl1SecurityTotal
        gl1Entry.Reliability = gl1ReliabilityTotal
        gl1Entry.Performance = gl1PerformanceTotal
        gl1Entry.Cost = gl1CostTotal
        gl1Entry.Operations = gl1OperationsTotal
        gl1Entry.Policy = gl1PolicyTotal
        gl1Entry.Total = (gl1SecurityTotal + gl1ReliabilityTotal + gl1PerformanceTotal + gl1CostTotal + gl1OperationsTotal + gl1PolicyTotal)

        gl1Entries.push(gl1Entry)
    }
        
    return gl1Entries;
}



function getGroupLevel1Values() {
    //check cache if not there query DB save to cache and then return value
    //db.executeJSONStoredProc('getGroupingLevel1Totals001')
    //(async () => await db.executeStoredProc('getGroupingLevel1Totals001'))();
    return new Promise(function (resolve, reject) {
        db.executeStoredProc('getGroupingLevel1Totals001').then(result => (resolve(result))).catch(err => {
            reject(err)
        })
    })
    //var rset
    

    //return rset
}

function getGroupLevel2Values() {
    //check cache if not there query DB save to cache and then return value
    return new Promise(function (resolve, reject) {
        db.executeStoredProc('getGroupingLevel2Totals001').then(result => (resolve(result))).catch(err => {
            reject(err)
        })
    })
}

function getRunSettings() {
    return new Promise(function (resolve, reject) {
        db.executeStoredProc('getLastRunSettings001').then(result => (resolve(result))).catch(err => {
            reject(err)
        })
    })
}

function getTechDebtPointScores () {
    //check cache if not there query DB save to cache and then return value
    return new Promise(function (resolve, reject) {
        db.executeStoredProc('getTechDebtPointScores002').then(result => (resolve(result))).catch(err => {
            reject(err)
        })
    })
}

function getBudgetValues() {
    //check cache if not there query DB save to cache and then return value
    
}

function filterRecordSet(recordSetToFilter, entryType, filterKey) {
    var filteredRecordSet

    switch (entryType) {
        case "gl2":
            return recordSetToFilter.filter(function (objToFilter) {
                if (objToFilter.groupingLevel2 == filterKey) {
                    return true;
                } else {
                    return false;
                }
            })
        case "gl1":
            return recordSetToFilter.filter(function (objToFilter) {
                if (objToFilter.groupingLevel1 == filterKey) {
                    return true;
                } else {
                    return false;
                }
            })
        case "env":
            return recordSetToFilter.filter(function (objToFilter) {
                if (objToFilter.environmentValue == filterKey) {
                    return true;
                } else {
                    return false;
                }
            })
        case "tier":
            return recordSetToFilter.filter(function (objToFilter) {
                if (objToFilter.criticalityValue == filterKey) {
                    return true;
                } else {
                    return false;
                }
            })
    }
    return filteredRecordSet
}

function buildEntry(recordSetToParse, itemName) {
    //assumes that recordSetToParse has already been filtered down to correct scope, e.g., grouoping Level2
    builtEntry = {}
    builtEntry.Name = itemName
    
    builtEntry.Security = buildPointsEntry(recordSetToParse, "Security")
    builtEntry.Reliability = buildPointsEntry(recordSetToParse, "HighAvailability")
    builtEntry.Cost = buildPointsEntry(recordSetToParse, "Cost")
    builtEntry.OperationalExcellence = buildPointsEntry(recordSetToParse, "OperationalExcellence")
    builtEntry.Performance = buildPointsEntry(recordSetToParse, "Performance")
    builtEntry.Policy = buildPointsEntry(recordSetToParse, "Policy")
    builtEntry.Points = builtEntry.Security.Points + builtEntry.Reliability.Points + builtEntry.Cost.Points + builtEntry.OperationalExcellence.Points + builtEntry.Performance.Points + builtEntry.Policy.Points
    //need to do for each category
    return builtEntry
}

function buildPointsEntry(recordSetToParse, category) {

    var entries = recordSetToParse.filter(function (objToFilter) {
        if (objToFilter.category == category) {
            return true;
        } else {
            return false;
        }
    })
    
    let pointsEntry = {}
    
    pointsEntry.Points = 0
    pointsEntry.High = 0
    pointsEntry.Low = 0
    pointsEntry.Medium = 0

    for (i=0;i < entries.length;i++) {
        pointsEntry.Points += entries[i].TechDebtPoints
        switch(entries[i].impact) {
            case "Medium":
                pointsEntry.Medium += entries[i].RecommendationCount
            case "High":
                pointsEntry.High += entries[i].RecommendationCount
            case "Low":
                pointsEntry.Low += entries[i].RecommendationCount
        }
    }

    return pointsEntry
}







exports.buildLeaderBoard = buildLeaderBoard;



