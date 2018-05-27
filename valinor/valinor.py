from flask import Flask

from basicconfig import get_config
conf = get_config()

app = Flask(__name__)
app.config.from_object(__name__)

@app.route('/add_robot')
def add_robot():
	pass

@app.route('/del_robot')
def del_robot():
	pass

@app.route('/robot_on/')
def turn_robot_on():
	pass

@app.route('/robot_off')
def turn_robot_off():
	pass

if __name__ == '__main__':
	settings = get_server_settings()
	app.debug = True
	app.run(host=conf.LOCAL_HOST, port=conf.VALINOR_PORT)