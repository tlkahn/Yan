require('dotenv').config()
const mongo = require('mongodb')
var MongoClient = mongo.MongoClient;
var url = "mongodb://127.0.0.1:27017/test";
var logger = require('morgan');
var passport = require('passport');
var LocalStrategy = require('passport-local').Strategy;
var clc = require('cli-color');

const jwt = require('jwt-simple');
const secret = process.env.secret;

const logError = function(err) {
    if (err.message) {
        console.log(clc.red("error: ", err.message));
    }
    else
        console.log(clc.red("error: ", err));
}

const logSuccess = function (message) {
    console.log(clc.blue(message));
}


const express = require('express')
var bodyParser = require('body-parser');
const app = express()

app.use(logger('dev'));

app.use(bodyParser.json());
app.use(bodyParser.urlencoded({
  extended: true
}));
app.use(passport.initialize());

const mongoose = require('mongoose');
const Schema = mongoose.Schema;
const passportLocalMongoose = require('passport-local-mongoose');

const AccountModel = new Schema({
    username: String,
    password: String
});

AccountModel.plugin(passportLocalMongoose);

var Account = mongoose.model('accounts', AccountModel);

// passport config
passport.use(new LocalStrategy(Account.authenticate()));
passport.serializeUser(Account.serializeUser());
passport.deserializeUser(Account.deserializeUser());

// mongoose
mongoose.connect('mongodb://localhost/test');

app.post('/register', (req, res, next) => {
    console.log("req.body.username", req.body.username)
    console.log("req.body.password", req.body.password)
    Account.register(new Account({ username: req.body.username }), req.body.password, (err, account) => {
        if (err) {
            logError(err)
            res.send({
                status: 'failure',
                message: err.message
            })
        }
        else {
            passport.authenticate('local')(req, res, () => {
                console.log("register success!")
                 res.send({
                    status: 'success',
                    message: 'register success'
                 })
            });
        }
    });
});

app.post('/login', passport.authenticate('local'), (req, res, next) => {
    logSuccess("login success!")
    let result = {
        status: 'success',
        message: 'login success',
        userId: req.user.id,
        username: req.user.username
    }
    let token = jwt.encode(result, secret);
    result['token'] = token;
    res.jsonp(result);
});

app.get('/ping', (req, res) => {
    res.status(200).send("pong!");
});

app.get('/', function(req, res) {
    let response = 'Hello at ' + new Date()
    res.send(response)
})

app.get('/users/:user_id/articles', function(req, res) {

    var findDocuments = function(db, userId, callback) {
        var collection = db.collection('articles');
        collection.find({userId: userId}).toArray(function(err, docs) {
            callback(docs);
        });
    }

    let token = req.query.token

    if (typeof token !== 'undefined' && token) {
        let decodedObj = jwt.decode(token, secret);
        let userId = decodedObj.userId
        MongoClient.connect(url, function(err, db) {
            findDocuments(db, userId, function(docs) {
                res.jsonp(docs)
            });
        });
    }
    else {
        res.jsonp({
            status: 'failure',
            message: 'unauthorized'
        })
    }
})

app.post('/articles', function(req, res) {
    MongoClient.connect(url, function(err, db) {
        if (err) throw err;
        db.collection("articles").insert({
            header: req.body.header,
            content: req.body.content
        })
    });
})

if (app.get('env') === 'development') {
    app.use(function(err, req, res, next) {
        res.status(err.status || 500);
        logError(err)
    });
}

app.listen(3000, function() {
    console.log('Example app listening on port 3000!')
})
