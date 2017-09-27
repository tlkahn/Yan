require('dotenv').config()
const mongo = require('mongodb')
var MongoClient = mongo.MongoClient;
var url = "mongodb://127.0.0.1:27017/test";
var logger = require('morgan');
var passport = require('passport');
var LocalStrategy = require('passport-local').Strategy;
var clc = require('cli-color');
var ObjectId = require('mongodb').ObjectID;

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
app.set('json spaces', 40);
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
                let result = {
                    status: 'success',
                    message: 'register success',
                    userId: req.user.id,
                    username: req.user.username
                }
                let token = jwt.encode(result, secret);
                result['token'] = token;
                res.jsonp(result)
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
    console.log("secret: ", secret)
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

    var findDocuments = function(db, userId, topArticleId, callback) {
        var collection = db.collection('articles');
        var oid = new ObjectId(topArticleId);
        console.log(clc.yellow("finding docs for ", topArticleId))
        collection.find({_id: { $gt: oid },
                      userId: userId
        }).sort({
            _id: -1
        }).toArray(function(err, docs) {
            console.log(clc.blue(JSON.stringify(docs)))
            callback(docs);
        });
    }

    let token = req.query.token
    let topArticleId = req.query.topArticleId
    console.log(clc.green("token: ", token))
    console.log(clc.green("top article id: ", topArticleId))
    if (typeof topArticleId == "undefined" || topArticleId.length == 0) {
        topArticleId = 0
    }

    if (typeof token !== 'undefined' && token) {
        let decodedObj = jwt.decode(token, secret);
        let userId = decodedObj.userId
        MongoClient.connect(url, function(err, db) {
            findDocuments(db, userId, topArticleId, function(docs) {
                return res.jsonp(docs)
            });
        });
    }
    else {
        return res.jsonp({
            status: 'failure',
            message: 'unauthorized'
        })
    }
})

app.post('/articles', function(req, res) {
    console.log(clc.yellow("posted article from app"))
    MongoClient.connect(url, function(err, db) {
        if (err) throw err;
        db.collection("articles").insert({
            header: req.body.header,
            content: req.body.content,
            userId: req.body.userId
        }, (err, docs) => {
            if (err) {
                console.log(clc.red("error when inserting new docs"))
            }
            console.log(clc.blue("insertion docs completed."))
            return res.jsonp(docs)
        })
    })
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
