# classroomLEDs

There are four components that comprise this project:

* raspi: A python script that reads the schedule of scenes from the server and controls the LEDs.
* server: A node.js server that publishes a CRUD API.
* webApp: A flask app that hosts users, profiles, and the ability to schedule and override scenes.
* mobileApp: A flutter app that displays the scenes and supports editing the scenes.


## raspi

### installation

* Start with a clean installation of raspios. This project was created with all full image of buster.
* Step through the Welcome to Raspberry Pi wizard, including updating software.
* [Enable SPI](https://learn.adafruit.com/adafruits-raspberry-pi-lesson-4-gpio-setup/configuring-spi) on the Raspberry Pi and reboot.
* Clone this repository into /home/pi/GitHub/.
* Change to the raspi directory.
* Upgrade the setuptools module: `pip3 install --upgrade setuptools`
* Install the required python modules: `pip3 install -r requirements.txt`
* Install and enable the service:

```
sudo cp classroomLEDs.service  /etc/systemd/system/
sudo chmod u+rwx /etc/systemd/system/classroomLEDs.service
sudo systemctl enable classroomLEDs
```

* Reboot the pi

### hardware configuration

This component is designed drive Adafruit DotStar LEDs using SPI.

* The black wire from the breadboard should be connected to the Pi GND
* The yellow wire to the Pi SCLK
* The green wire, to the Pi MOSI

Adafruit has a [tutorial](https://learn.adafruit.com/adafruit-dotstar-leds/python-circuitpython#python-computer-wiring-3004880-8) for wiring DotStar LEDs to the Raspberry Pi. Note that given the number of LEDs being driven, this system is designed to be used with an external 5V, 10A power supply.

* The LED strip connects to the power supply via the 2.1 mm jack.
* The LED strip connects to the breadboard via the 4-pin JST SM receptacle. 

### design

Adafruit [recommends](https://learn.adafruit.com/adafruit-neopixel-uberguide/powering-neopixels) adding a large capacitor (1000 µF, 6.3V) across power and ground. The breadboard has a 4700 µF capacitor across power and ground.

DotStars are 5 V devices and the Raspberry Pi provides 3.3 V. Therefore, as [recommended](https://learn.adafruit.com/adafruit-dotstar-leds/power-and-connections#connecting-dotstar-leds-3004523-2) by Adafruit, the [74AHCT125 quad level-shifter](https://www.adafruit.com/product/1787) is used to boost the 3V signals to 5V.


## server

### Production Server Deployment

Based on [this tutorial](https://ourcodeworld.com/articles/read/977/how-to-deploy-a-node-js-application-on-aws-ec2-server).

* Create a new EC2 instance used on Ubuntu.
* Open ports for HTTP and HTTPS when walking through the EC2 wizard.
* Generate a key pair for this EC2 instance. Download and save the private key, which is needed to connect to the instance in the future.
* After the EC2 instance is running, click on the Connect button the EC2 Management Console for instructions on how to ssh into the instance.
* On the EC2 instance, [install](https://github.com/nodesource/distributions/blob/master/README.md) Node.js v12

```
curl -fsSL https://deb.nodesource.com/setup_12.x | sudo -E bash -
sudo apt-get install -y nodejs
```

* On the EC2 instance, install nginx: `sudo apt-get -y install nginx`
* Create a reverse proxy for the Classroom LEDs Flask server. In the file /etc/nginx/sites-enabled/classroomLEDs:

```
server {
	# listen on port 80 (http)
	listen 80;
	server_name classroomLEDs.nnhsse.org;

	# write access and error logs to /var/log
	access_log /var/log/classroomLEDs_access.log;
	error_log /var/log/classroomLEDs_error.log;

	location / {
		# forward application requests to the gunicorn (Flask) server
		proxy_pass http://localhost:5000;
		proxy_redirect off;
		proxy_set_header Host $host;
		proxy_set_header X-Real-IP $remote_addr;
		proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
	}
	
	location /leds {
		# forward application requests to the node server
		proxy_pass http://localhost:3000;
		proxy_redirect off;
		proxy_set_header Host $host;
		proxy_set_header X-Real-IP $remote_addr;
		proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
	}
}
```

* Restart the nginx server: `sudo service nginx reload`
* Install and configure [certbot](https://certbot.eff.org/lets-encrypt/ubuntufocal-nginx)
* Clone this repository from GitHub.
* Inside of the webApp directory for this repository install the Flask dependencies:

```
sudo apt-get install python3-venv
python3 -m venv venv
source ./venv/bin/active
pip install wheel
pip install -r requirements.txt
```

* Inside of the server directory for this repository install the node dependencies: `npm install`
* Install Production Manager 2, which is used to keep the node server running and restart it when changes are pushed to master:

```
sudo npm install pm2 -g
sudo pm2 --name classroomLEDsNode start app.js
```

* Inside of the webApp directory for this repository install the Flask dependencies: `pip3 install -r requirements.txt`
* Add the Flask app to Production Manager 2 to keep the Flask server running and restart it when changes are pushed to master:

```
sudo pm2 --name classroomLEDsFlask start boot.sh
```

* Verify that the node and Flask servers are running: `sudo pm2 list`
* Configure pm2 to automatically run when the EC2 instance restarts: `sudo pm2 startup`
* Add a crontab entry to pull from GitHub every 15 minutes: `crontab -e`

```
*/15 * * * * cd /home/ubuntu/classroomLEDs && git pull
```

* Restart the node server: `sudo pm2 restart classroomLEDsNode`
	
### design

The server provides a CRUD JSON API for multiple LED strips and multiple scenes per LED strip.

All of the LED strips and their scenes can be retrieved with a GET request to /leds.

Each LED strip has an ID and a list of scenes. The attributes of a specific LED strip, including its scenes, can be retrieved with a GET request to /leds/*ledID*.

All of the scenes of a specific LED strip, can be retrieved with a GET request to /leds/*ledID*/scenes. In addition, new scenes can be created with a POST request.

LED Strip, Attributes:

* id: int, unique identifier for each LED strip

* scenes: list of scenes

Scene, Attributes:

* id: int; required; unique identifier for each scene

* color: string; required; 8-digit hex string specifying brightness, red, green, blue color; e.g., "ffrrggbb"

* brightness: double between 0 and 1.0; required; higher number is brighter

* mode: string; required; currently "solid" or "pulse" are supported

* day_of_week: string; optional; "monday", "tuesday", etc.; if specified, is the default scene on that day of the week at the specified time

* date: string; ISO 8601 format; optional; if specified, replaces the regularly scheduled scene for that day and time; the month, day and year is used and the time is ignored

* override_duration: int; optional; number of minutes to override the currently active scene; 0 will override the currently active scene until the next scheduled scene

* start_time: string; required; ISO 8601 format; month, day, and year must be set to "1900-01-01"
     * for a day_of_week scene; time specifies the starting time of the scene
     * for a date scene; time specifies the starting time of the scene
     * for an override scene; time specifies the starting time of the override, date is ignored
	
The attributes of a specific scene, can be retrieved with a GET request to /leds/*ledID*/scenes/*sceneID*. A specific scene can be updated with a PUT request or deleted with DELETE request.

The main thread in the script gets the scenes for the LED strip with ID 1 every 5 seconds. The most recent override or scene whose time has passed determines the state of the LEDs. The LEDs are updated in a separate thread every 10 milliseconds to support the pulse mode.


## webApp

### installation

* Start in VS Code and clone this repository
* Change to the webApp directory
* Install python if not done already
* Create a python virtual environment: `python -m venv venv`
* Activate the virtual environment: `.\venv\Scripts\activate`
* Install flask: `pip install flask`
* Install the required python modules: `pip install -r requirements.txt`
* Set the FLASK_APP environment variable: `set FLASK_APP=webApp.py`
* Run flask: `flask run`

On startup every time:

* Go to the webApp directory
* Start the virtual environment: `.\venv\Scripts\activate`
* Set the FLASK_APP environment variable: `set FLASK_APP=webApp.py`
* Run flask: `flask run`

Create raspi server in a separate terminal or on the Raspberry Pi:
* Go to server directory
* `node app.js`
* In the URL go to /leds: `http://<ip address>/leds`

After installing anything new, update requirements.txt
* `pip freeze > requirements.txt`

### design

The home page is currently the only page. On this page, ou can view every scene on a table, organized by day of week and start time. It features an add scene button, which allows to add a new scene to the JSON file, which will also show up on the home page table. You can also edit and delete each scene from the table individually using the buttons asigned to each scene. Currently, the start time box has no validation on the edit or add scene forms, so it is possible to break the JSON file by adding a scene with an invalid start time.

## mobileApp

### installation

* [Setup](https://flutter.dev/docs/get-started/install) the machine to support Flutter development.
* Clone this repository.
* Open the mobileApp/classroom_leds folder in VS Code
* Open the cubitSchmit branch in VS Code (This has the most recent prototype mobile app code that was not finished)
* Run the app.

### design

The homepage displays the attributes that are currently being displayed, such as the ID of the Scene, the color, the start time, etc. 
In the future, it should display the color name, not the hexcode, and the attribute organization should be cleaned up.

There are multiple pages that can be accessed in the bottom hotbar. In the future, these pages can be used to display more data, such as the override functions.

The add Scene function must be modified, because there is currently no page to display the added Scene and the inputs aren't accurate.

The color scheme of the app as a whole should be modified and coordinated with the Web App.

The internal design of the app needs a review and probably significant cleanup. For example: the homepage uses a stateless widget when a stateful widget would
be more useful for refreshing the page.

## Unfinished User Stories:

### LED Code:

* As a teacher, I want to override a previous schedule of colors, brightnesses, and patterns for the LEDs in my classroom with a new schedule for any predetermined date in order to accommodate a unique bell schedule via the use of a json file.
* As a teacher, I want to have multiple LED strands in my classroom and have them function as a single strand (e.g., follow the same schedule, have a single override) via JSON configuration
	
### Mobile App:
	
* As a teacher, I want to specify, via a mobile app, the color and brightness for the LEDs in my classroom in order to customize them to the activity or classes mood.
* As a teacher, I want to override the current color, brightness, and pattern for the LEDs in my classroom for a specified period of time in order to accommodate a unique activity or change in plans via use of a mobile app.
* As a teacher, I want to specify a schedule of colors, brightnesses, and patterns for the LEDs in my classroom via a Mobile App in order to customize them to the activity or bell schedule in advance.
* As a teacher, I want to override a previous schedule of colors, brightnesses, and patterns for the LEDs in my classroom on my Web App with a new schedule for any predetermined date in order to accommodate a unique bell schedule via the use of a mobile app.
* As a teacher, I want to have multiple LED strands in my classroom and have them function as a single strand (e.g., follow the same schedule, have a single override) via mobile app configuration

### Web App:
* As a teacher, I want to override a previous schedule of colors, brightnesses, and patterns for the LEDs in my classroom on my Web App with a new schedule for any predetermined date in order to accommodate a unique bell schedule. (LOW PRIORITY)
* As a teacher, I want to have multiple LED strands in my classroom and have them function as a single strand (e.g., follow the same schedule, have a single override) via web app configuration
* As a teacher, I want to be able to change scenes for multiple days at a time to make a consistent schedual

