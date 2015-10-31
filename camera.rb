class Camera
	attr_reader :position, :target, :horizontal_angle, :vertical_angle
	def initialize(parent_window)
		@parent_window = parent_window
		@position = Vector3D.new(2.0, 2.5, 5.0)
		@target = Vector3D.new(0.0, 0.0, 0.0)
		@up = Vector3D.new(0.0, 1.0, 0.0)
		@ratio, @fovy, @far, @near = @parent_window.width.to_f / @parent_window.height.to_f, 60.0, 1000.0, 0.01
		@horizontal_angle = 0.0
		@vertical_angle = 0.0
		@distance = 3.0
		@speed = 0.08
		@angle_speed = 1.9
		@collision_box = Box2D.new(Vector3D.new(@position.x - 0.5, @position.y, @position.z - 0.5), 1.0, 1.0)
		@parent_window.mouse_x, @parent_window.mouse_y = @parent_window.width / 2, @parent_window.height / 2
		@last_mouse_x, @last_mouse_y = @parent_window.mouse_x, @parent_window.mouse_y
		@mouse_sensitivity = 0.04

		@on_ground = false
		@gravity = -0.01
		@velocity_y = 0.0

		adjust_target
	end

	def update
		speed = @speed

		old_x, old_z = @position.x, @position.z

		handle_jump

		# diagonal speed
		if @parent_window.button_down?(Gosu::KbW) or @parent_window.button_down?(Gosu::KbS)
			if @parent_window.button_down?(Gosu::KbA) or @parent_window.button_down?(Gosu::KbD)
				speed *= 0.7
			end
		end

		if @parent_window.button_down?(Gosu::KbW)
			@position.x += speed * Math::cos(@horizontal_angle * Math::PI / 180.0)
			@position.z += speed * Math::sin(@horizontal_angle * Math::PI / 180.0)
		elsif @parent_window.button_down?(Gosu::KbS)
			@position.x -= speed * Math::cos(@horizontal_angle * Math::PI / 180.0)
			@position.z -= speed * Math::sin(@horizontal_angle * Math::PI / 180.0)
		end

		if @parent_window.button_down?(Gosu::KbA)
			@position.x += speed * Math::cos((@horizontal_angle - 90.0) * Math::PI / 180.0)
			@position.z += speed * Math::sin((@horizontal_angle - 90.0) * Math::PI / 180.0)
		elsif @parent_window.button_down?(Gosu::KbD)
			@position.x -= speed * Math::cos((@horizontal_angle - 90.0) * Math::PI / 180.0)
			@position.z -= speed * Math::sin((@horizontal_angle - 90.0) * Math::PI / 180.0)
		end

		# ANGLE
		if @parent_window.button_down?(Gosu::KbUp)
			@vertical_angle += @angle_speed
		elsif @parent_window.button_down?(Gosu::KbDown)
			@vertical_angle -= @angle_speed
		end

		if @parent_window.button_down?(Gosu::KbLeft)
			@horizontal_angle -= @angle_speed
		elsif @parent_window.button_down?(Gosu::KbRight)
			@horizontal_angle += @angle_speed
		end

		# ANGLE WITH MOUSE
		if @parent_window.mouse_x != @last_mouse_x
			@horizontal_angle += (@parent_window.mouse_x - @last_mouse_x) * @mouse_sensitivity
			@parent_window.mouse_x = @parent_window.width / 2
			@last_mouse_x = @parent_window.mouse_x
		end

		if @parent_window.mouse_y != @last_mouse_y
			@vertical_angle -= (@parent_window.mouse_y - @last_mouse_y) * @mouse_sensitivity
			@parent_window.mouse_y = @parent_window.height / 2
			@last_mouse_y = @parent_window.mouse_y
		end

		@vertical_angle = -35.0 if @vertical_angle < -35.0
		@vertical_angle = 35.0 if @vertical_angle > 35.0

		# collision check
		@collision_box.origin.x = @position.x - 0.5
		@collision_box.origin.z = @position.z - 0.5

		if @parent_window.map.block?(@collision_box)
			if !@parent_window.map.block?(Box2D.new(Vector3D.new(@position.x - 0.5, @position.y, old_z - 0.5), 1.0, 1.0))
				@position.z = old_z
			elsif !@parent_window.map.block?(Box2D.new(Vector3D.new(old_x - 0.5, @position.y, @position.z - 0.5), 1.0, 1.0))
				@position.x = old_x
			else # neither x or z are allowed
				@position.x = old_x
				@position.z = old_z
			end
		end

		adjust_target
	end

	def adjust_target
		@target.x = @position.x + @distance * Math::cos(@horizontal_angle * Math::PI / 180.0)
		@target.y = @position.y + @distance * Math::sin(@vertical_angle * Math::PI / 180.0)
		@target.z = @position.z + @distance * Math::sin(@horizontal_angle * Math::PI / 180.0)
	end

	def look
		glEnable(GL_DEPTH_TEST)
		glEnable(GL_TEXTURE_2D)
		#~ glClearColor(0.0, 1.0, 0.0, 0.0)
		glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)

		glEnable(GL_ALPHA_TEST)
		glAlphaFunc(GL_GREATER, 0)

		glMatrixMode(GL_PROJECTION)
		glLoadIdentity
		gluPerspective(@fovy, @ratio, @near, @far)

		glMatrixMode(GL_MODELVIEW)
		glLoadIdentity
		gluLookAt(@position.x, @position.y, @position.z, @target.x, @target.y, @target.z, @up.x, @up.y, @up.z)
	end

	def handle_jump
		if @parent_window.button_down? Gosu::KbSpace
			apply_force
		else
			reset_velocity
		end

		@velocity_y += @gravity
		@position.y += @velocity_y

		if @position.y < 2.5
			@position.y = 2.5
			@velocity_y = 0.0
			@on_ground = true
		end
	end

	def apply_force
		if @on_ground
			@velocity_y = 0.2
			@on_ground = false
		end
	end

	def reset_velocity
		if @velocity_y > 0.1
			@velocity_y = 0.1
		end
	end
end
