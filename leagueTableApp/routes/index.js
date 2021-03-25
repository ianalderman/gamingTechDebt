var express = require('express');
var router = express.Router();
var leagueTable = require("../leagueTable.js");

/* GET home page. */
//router.get('/', function(req, res, next) {
router.get('/', async function(req, res, next){
  const leaderBoard = await leagueTable.buildLeaderBoard();
  res.render('index', { title: 'Cloud Governance Portal', leaderBoard });
});

/*
router.get('/metastore', async function(req, res, next){
  res.render('metastore', { title: 'Metastore'});
});*/

module.exports = router;
