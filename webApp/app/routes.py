import datetime
from flask import render_template, flash, redirect, url_for, request
from werkzeug.urls import url_parse
from flask_login import current_user, login_user, logout_user, login_required
from app import app, db #importing the app variable (right) defined in the app package (left)
from app.forms import LoginForm, RegistrationForm, EditProfileForm, Override, Date, DayOfWeek, EditSchedule, AddScene
from app.models import User
import requests
import json
import time

#from decimal import Decimal

nodeServer = "http://localhost:3000"
realServer = "https://classroomleds.nnhsse.org"


@app.before_request
def before_request():
    if current_user.is_authenticated:
        current_user.last_seen = datetime.datetime.utcnow()
        db.session.commit()


@app.route('/')
@app.route('/index')
@login_required
def index():
#    URL_get = "http://localhost:3000/leds/1"

#    r = requests.get(url = URL_get)

#    data = r.json() #json object

#    data_dumps = json.dumps(data)

#    data_dict = json.loads(data_dumps)

    #post is create a new scene and put is update the scene

    #scenes without a specific scene number can be used to post, but if there is a scene it will update with put

#    URL_put = "http://localhost:3000/leds/1/scenes/60" 

#    data_put = {            
#        "id": 22,
#        "time":"2020-10-19T13:30:00.000",
#        "color":"ff000000",
#        "brightness": 2.0,
#        "mode":"solid"}

#    put_dumps = json.dumps(data_put) #dump creates string object

#    put_dict = json.loads(put_dumps)

#    r1 = requests.put(URL_put, json = data_put)
#---Post Info Below---
#    URL_post = "http://localhost:3000/leds/1/scenes"

#    test1 = 1
#    test2 = 2
#    testtime = "2020-10-19 13:30:00"

#    data_post = {
        # id doesn't matter "id": 90,
#        "color": test2,
#        "brightness": test1,
#        "mode": test2,
#        "day_of_week": "Monday",
#        "start_time": testtime}

#    post_dumps = json.dumps(data_post)

#    post_dict = json.loads(post_dumps)

#    r2 = requests.post(URL_post, json = data_post)

#        {
#            'author': {'username': 'Bill'},
#            'body': "ID: " + str(data_dict.get('scenes')[0]['id'])
#        },
#        {
#            'author': {'username': 'Bill'},
#            'body': "Time: " + data_dict.get('scenes')[0]['time']
#        }
#        {
#            'author': {'username': 'Bill'},
#            'body': r1.text
#        }

    posts1 = [
        {
            'author': {'username': 'Bill'},
            'body': "Day of Week: Specify a day of the week (monday, tuesday, wednesday, \
                thursday, friday, saturday, sunday) in order to create an override for that \
                day of the week."
        }
    ]
    
    posts2 = [
        {
            'author': {'username': 'Bill'},
            'body': "Date: Specify a date using ISO 8601 notation (\"YYYY-MM-DD\") in order \
                to override the LEDs on that specific date."
        }
    ]

    posts3 = [
        {
            'author': {'username': 'Bill'},
            'body': "Override Duration: Override the LEDs right now for a specified amount \
                of time in minutes."
        }
    ]
    #CODE RIGHT HERE TO PUT IN DATA
    r = requests.get(nodeServer + "/leds/1")
    data = r.json()
    data_dumps = json.dumps(data)
    dataDict = json.loads(data_dumps)['scenes']
    #print(dataDict)
    dataDict.sort(key=lambda k: k['start_time'])

    #appending date strings to only be the time
    for i in dataDict:
        sch_date = datetime.datetime.strptime(i["start_time"], '%Y-%m-%dT%H:%M:%S.%f')
        sch_time = datetime.time(sch_date.hour, sch_date.minute, sch_date.second)
        i["start_time"] = sch_time
        i["color"] = "#" + i["color"][2:]
    

    
    return render_template('index.html', title='Home', posts1=posts1, posts2 = posts2, posts3 = posts3, dataDict = dataDict)


@app.route('/login', methods=['GET', 'POST'])
def login(): #Figure out which 
    if current_user.is_authenticated:
        return redirect(url_for('index'))
    form = LoginForm()
    if form.validate_on_submit():
        user = User.query.filter_by(username=form.username.data).first() #finding user if stored in database
        if user is None or not user.check_password(form.password.data): #invalid login attempts
            flash('Invalid username or password')
            return redirect(url_for('login'))
        login_user(user, remember=form.remember_me.data)
        next_page = request.args.get('next')
        if not next_page or not next_page.startswith('/'): #protect from malicious urls
            next_page = url_for('index')
        return redirect(next_page)
    return render_template('login.html', title='Sign In', form=form)


@app.route('/logout')
def logout():
    logout_user()
    return redirect(url_for('index'))


@app.route('/register', methods=['GET','POST'])
def register():
    if current_user.is_authenticated:
        return redirect(url_for('index'))
    form = RegistrationForm()
    if form.validate_on_submit():
        user = User(username=form.username.data, email=form.email.data)
        user.set_password(form.password.data)
        db.session.add(user)
        db.session.commit()
        flash('Congratulations, you are now a registered user!')
        return redirect(url_for('login'))
    return render_template('register.html', title='Register', form=form)


@app.route('/user/<username>')
@login_required
def user(username):
    user = User.query.filter_by(username=username).first_or_404()
    posts = [
#        {'author': user, 'body': 'I\'m overriding the current color, brightness, and pattern of the LEDs!'}, #Customizable
#        {'author': user, 'body': 'I\'m scheduling the color, brightness, and pattern of the LEDs!'}
    ]
    return render_template('user.html', user=user, posts=posts)


@app.route('/edit_profile', methods=['GET', 'POST'])
@login_required
def edit_profile():
    form = EditProfileForm(current_user.username)
    if form.validate_on_submit():
        current_user.username = form.username.data
        current_user.about_me = form.about_me.data
        db.session.commit()
        flash('Your changes have been saved.')
        return redirect(url_for('edit_profile'))
    elif request.method == 'GET':
        form.username.data = current_user.username
        form.about_me.data = current_user.about_me
    return render_template('edit_profile.html', title='Edit Profile', form=form)


@app.route('/override', methods=['GET', 'POST'])
@login_required
def override():
    form = Override(current_user.username)
    if form.validate_on_submit():
        URL_post = "http://192.168.4.50:3000/leds/1/scenes"

        color = form.color.data
        brightness = form.brightness.data
        mode = form.mode.data
        override_duration = form.override_duration.data
        start_time1 = form.start_time.data

        data_post = {
            "color": "ff" + color,
            "brightness": brightness,
            "mode": mode,
            "override_duration": override_duration,
            "start_time": "1900-01-01T" + start_time1 + ":00.000"}        
        
        post_dumps = json.dumps(data_post)
        post_dict = json.loads(post_dumps)
        r_post = requests.post(URL_post, json = data_post)

        db.session.commit()
        flash('Your changes have been saved.')
        return redirect(url_for('index'))
    return render_template('override.html', title='Override', form=form)


@app.route('/date', methods=['GET', 'POST'])
@login_required
def date():
    form = Date(current_user.username)
    if form.validate_on_submit():
        URL_post = "http://192.168.4.50:3000/leds/1/scenes"

        color = form.color.data
        brightness = form.brightness.data
        mode = form.mode.data
        date = form.date.data
        start_time = form.start_time.data

        data_post = {
            "color": "ff" + color,
            "brightness": brightness,
            "mode": mode,
            "date": date + "T00:00:00.000",
            "start_time": "1900-01-01T" + start_time + ":00.000"}             

        post_dumps = json.dumps(data_post)
        post_dict = json.loads(post_dumps)
        r_post = requests.post(URL_post, json = data_post)

        db.session.commit()
        flash('Your changes have been saved.')
        return redirect(url_for('index'))
    return render_template('date.html', title='Date', form=form)


@app.route('/dayofweek', methods=['GET', 'POST'])
@login_required
def dayofweek():
    form = DayOfWeek(current_user.username)
    if form.validate_on_submit():
        URL_post = "http://192.168.4.50:3000/leds/1/scenes"

        color = form.color.data
        brightness = form.brightness.data
        mode = form.mode.data
        day_of_week = form.day_of_week.data
        start_time = form.start_time.data

        data_post = {
            "color": "ff" + color,
            "brightness": brightness,
            "mode": mode,
            "day_of_week": day_of_week,
            "start_time": "1900-01-01T" + start_time + ":00.000"}

        post_dumps = json.dumps(data_post)
        post_dict = json.loads(post_dumps)
        r_post = requests.post(URL_post, json = data_post)

        db.session.commit()
        flash('Your changes have been saved.')
        return redirect(url_for('index'))
    return render_template('dayofweek.html', title='Day of Week', form=form)


@app.route('/editschedule/<id>', methods=['GET', 'POST'])
@login_required
def editschedule(id):
    form = EditSchedule(current_user.username)


    if form.validate_on_submit():
        URL_put = nodeServer + "/leds/1/scenes/{}".format(id)


        color = form.color.data
        brightness = form.brightness.data
        mode = form.mode.data
        start_time = form.start_time.data
        day = form.day_of_week.data

        
        data_put = {
            "id": id,
            "color": "ff" + color[1:],
            "brightness": brightness,
            "mode": mode,
            "day_of_week": day,
            "start_time": "1900-01-01T" + start_time + ":00.000"}

        print(data_put)    

        post_dumps = json.dumps(data_put)
        post_dict = json.loads(post_dumps)
        r_post = requests.put(URL_put, json = data_put)

        db.session.commit()
        flash('Your changes have been saved.')
        return redirect(url_for('index'))
    
    # GET request to access current JSON data
    r = requests.get(nodeServer + "/leds/1")
    data = r.json()
    data_dumps = json.dumps(data)
    dataDict = json.loads(data_dumps)['scenes']

    #currentScene = the scene which is being edited by user
    currentScene = dataDict[int(id)-1]

    #format the date to fit the text field properly
    sch_date = datetime.datetime.strptime(currentScene["start_time"], '%Y-%m-%dT%H:%M:%S.%f')

    #form.color.data = currentScene["color"][2:]
    form.brightness.data = currentScene["brightness"]
    form.mode.data = currentScene["mode"]
    if sch_date.hour < 10:
        form.start_time.data = "0" + str(sch_date.hour) + ":" + str(sch_date.minute)
    else:
        form.start_time.data = str(sch_date.hour) + ":" + str(sch_date.minute)
    form.day_of_week.data = currentScene["day_of_week"]

    return render_template('editschedule.html', title='Day of Week', form=form)

@app.route('/addscene', methods=['GET', 'POST'])
@login_required
def addscene():
    form = AddScene(current_user.username)

    # GET request to access current JSON data
    r = requests.get(nodeServer + "/leds/1")
    data = r.json()
    data_dumps = json.dumps(data)
    dataDict = json.loads(data_dumps)['scenes']
    maxid = 0
    for scene in dataDict:
        if scene["id"] > maxid:
            maxid = scene["id"]
    currentid = maxid + 1

    if form.validate_on_submit():
        URL_post = nodeServer + "/leds/1/scenes"


        color = form.color.data
        brightness = form.brightness.data
        mode = form.mode.data
        start_time = form.start_time.data
        day = form.day_of_week.data

        
        data_post = {
            "id": currentid,
            "color": "ff" + color[1:],
            "brightness": brightness,
            "mode": mode,
            "day_of_week": day,
            "start_time": "1900-01-01T" + start_time + ":00.000"}
  

        post_dumps = json.dumps(data_post)
        post_dict = json.loads(post_dumps)
        r_post = requests.post(URL_post, json = data_post)

        db.session.commit()
        flash('Your changes have been saved.')
        return redirect(url_for('index'))
    


    return render_template('editschedule.html', title='Add Scene', form=form)


@app.route('/deleteScene/<id>', methods=['GET', 'POST'])
@login_required
def deleteScene(id):
    #form =


    #if form.validate_on_submit():
        URL_delete = nodeServer + "/leds/1/scenes/{}".format(id)


        requests.delete(URL_delete)

        db.session.commit()
        flash('Your changes have been saved.')
        return redirect(url_for('index'))
    