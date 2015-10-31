require "gosu"
require "opengl"
require "texplay"
require_relative "map.rb"
require_relative "camera.rb"

Gosu::enable_undocumented_retrofication

class Window < Gosu::Window
	attr_reader :camera, :map
	def initialize
		super(1280, 720, false)
		self.caption = "FPS"
		@map = Map.new(self, "map.png", "tileset.png", "walls.png")
		@camera = Camera.new(self)
		@aim = Gosu::Image.new(self, "aim.png", true)
		@character_minimap = Gosu::Image.new(self, "character_minimap.png", true)
		@map_bg = Gosu::Image.new(self, "map_bg.png", true)
	end
	
	def button_down(id)
		exit if id == Gosu::KbEscape
	end
	
	def draw_minimap
		chara_color = Gosu::Color.new(128, 0, 255, 0)
		map_color = Gosu::Color.new(128, 255, 255, 255)
		black_color = Gosu::Color.new(255, 255, 255, 255)
		clip_to(0, 0, 160, 120) do
			scale 6 do
				@map_bg.draw(0, 0, 0, 1, 1, black_color)
				x = @map.rect.width / 2
				y = @map.rect.length / 2 - 3
				z = 1
				angle = @camera.horizontal_angle + 90.0
				x_map = x - @camera.position.x - 0.1
				y_map = y - @camera.position.z + 0.05
					
				@map.map_texture.draw(x_map, y_map, 0, 1, 1, map_color)
				@character_minimap.draw_rot(x, y, z, angle, 0.5, 0.8, 1, 1, chara_color)
			end
		end
	end
	
	def draw
		gl do
			@camera.look
			@map.draw
		end
		@aim.draw((self.width + @aim.width) / 2, (self.height + @aim.height) / 2, 0)
		draw_minimap
	end
	
	def update
		@camera.update
	end
end

Window.new.show