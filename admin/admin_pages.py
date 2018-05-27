from flask import Blueprint
from myfunction import *


admin = Blueprint('admin', __name__)


@admin.route('/signup/')
def signup():
	pass
	

@admin.route('/signin/')
def signin():
	pass


@admin.route('/log_view/')
def log_view():
	pass


@admin.route('/watch_valinor/')
def watch_valinor():
	pass


@admin.route('/add_robot/')
def add_robot():
	# send a add robot msg to valinor
	pass


@admin.route('/del_robot/')
def del_robot():
	# send a del robot msg to valinor
	pass


@admin.route('/robot_on/')
def turn_robot_on():
	pass


@admin.route('/robot_off')
def turn_robot_off():
	pass

