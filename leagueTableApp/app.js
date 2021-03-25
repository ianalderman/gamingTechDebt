var createError = require('http-errors');
var express = require('express');
var path = require('path');
var cookieParser = require('cookie-parser');
var logger = require('morgan');



//var redis = require('redis');
//var tdsConnection = require('tedious').Connection
//var tdsRequest = require('tedious').Request
//var tdsTypes = require('tedious').TYPES
//const sql = require('mssql')

var app = express();
var envvar = process.env.NODE_ENV;



//if we are in dev we will read our sensistive env vars from local .env file
if (process.env.NODE_ENV !== 'production') {
  require('dotenv').config({ path: path.resolve(process.cwd(), 'local.env')})
}

var indexRouter = require('./routes/index');
//var metastoreRouter = require('./routes/metastore')

// view engine setup
app.set('views', path.join(__dirname, 'views'));
app.set('view engine', 'pug');

app.use(logger('dev'));
app.use(express.json());
app.use(express.urlencoded({ extended: false }));
app.use(cookieParser());
app.use(express.static(path.join(__dirname, 'public')));


app.use('/', indexRouter);

// catch 404 and forward to error handler
app.use(function(req, res, next) {
  next(createError(404));
});

// error handler
app.use(function(err, req, res, next) {
  // set locals, only providing error in development
  res.locals.message = err.message;
  res.locals.error = req.app.get('env') === 'development' ? err : {};

  // render the error page
  res.status(err.status || 500);
  res.render('error');  
});

/*
const router = require('express').Router();

router.get('/', (req, res, next, ) => {
    const testObj = {hello: 'Hey'};
    res.render('index', { testObj: JSON.stringify(testObj) });
});
*/



//app.get('/', function (req, res) {
//  res.send('Hello World!');
//});

module.exports = app;

//  link(rel="stylesheet", href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.7/css/bootstrap.min.css", integrity="sha384-BVYiiSIFeK1dGmJRAkycuHAHRg32OmUcww7on3RYdg4Va+PmSTsz/K68vbdEjh4u", crossorigin="anonymous")
//link(rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.7/css/bootstrap-theme.min.css", integrity="sha384-rHyoN1iRsVXV4nD0JutlnGaslCJuC7uwjduW9SVrLvRYooPp2bWYgmgJQIXwl/Sp", crossorigin="anonymous")

//script(src="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.7/js/bootstrap.min.js", integrity="sha384-Tc5IQib027qvyjSMfHjOMaLkfuWVxZxUPnCJA7l2mCWNIpG9mGCD8wGNIcPD7Txa", crossorigin="anonymous")


