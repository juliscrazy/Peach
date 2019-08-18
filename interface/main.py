import random
import logging

import flask

app = flask.Flask(__name__)
app.debug = False

@app.route("/")
def index():
    return flask.render_template("dashboard.html", botrunning=botrunning)

@app.route("/servers/")
def servers():
    return flask.render_template("servers.html")

@app.route("/stats/")
def stats():
    return flask.render_template("stats.html")

@app.route("/integrations/")
def integrations():
    return flask.render_template("integrations.html")

@app.route("/logs/")
def logs():
    return flask.render_template("logs.html")

@app.route("/functions/dashboard/stop/")
def stop():
    global botrunning    
    log.info("Attempting to stop the bot")
    botrunning = False
    return flask.redirect(flask.url_for("index"), code=302)
    #return flask.render_template("dashboard.html")

@app.route("/functions/dashboard/start/")
def start():  
    global botrunning
    print("start")
    botrunning = True
    print(botrunning)
    return flask.redirect(flask.url_for("index"), code=302)
    #return flask.render_template("dashboard.html")

if __name__ == "__main__":
    logging.basicConfig(format='%(asctime)s - %(levelname)s: %(message)s', level=logging.INFO, datefmt='%Y-%m-%d %H:%M:%S')
    log = logging.getLogger('cuddler-logger')
    allowedloggers = ['cuddler-logger']
    for loggers in logging.Logger.manager.loggerDict:
        if loggers not in allowedloggers:
            logging.getLogger(loggers).disabled = True
        else:
            pass
    
    botrunning = random.choice([True, False])
    log.info('Starting flask')
    try:
        app.run(host="0.0.0.0")
    except KeyboardInterrupt:
        connection.close()
