module Gosu
  class Image
    def get_rgb(x, y)
      result = get_pixel(x, y)
      return [(result[0] * 255).to_i, (result[1] * 255).to_i, (result[2] * 255).to_i]
    end
  end
end

class GLTexture
  # GOSU IMAGE -> OPENGL TEXTURE FIX
  # SOLVES PROBLEM WITH REPETITION / CROPING
  def initialize(p_win, filename)
    if filename.is_a?(Gosu::Image)
      gosu_image = filename
    else
      gosu_image = Gosu::Image.new(p_win, filename, true)
    end
    array_of_pixels = gosu_image.to_blob
    @texture_id = glGenTextures(1)
    glBindTexture(GL_TEXTURE_2D, @texture_id[0])
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, gosu_image.width, gosu_image.height, 0, GL_RGBA, GL_UNSIGNED_BYTE, array_of_pixels)
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST)
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST)
    gosu_image = nil
  end

  def get_id
    return @texture_id[0]
  end
end

class ObjModel
  def initialize(filename)
    @v = []; @vt = []; @vn = []; @f = []
    File.open(filename, "r").readlines.each do |line|
      line = line.chomp
      @v.push([line.split(" ")[1].to_f, line.split(" ")[2].to_f, line.split(" ")[3].to_f]) if line.include?("v ")
      @vt.push([line.split(" ")[1].to_f, line.split(" ")[2].to_f, line.split(" ")[3].to_f]) if line.include?("vt ")
      @vn.push([line.split(" ")[1].to_f, line.split(" ")[2].to_f, line.split(" ")[3].to_f]) if line.include?("vn ")
      if line.include?("f ")
        v1 = [line.split(" ")[1].split("/")[0].to_i, line.split(" ")[1].split("/")[1].to_i, line.split(" ")[1].split("/")[2].to_i]
        v2 = [line.split(" ")[2].split("/")[0].to_i, line.split(" ")[2].split("/")[1].to_i, line.split(" ")[2].split("/")[2].to_i]
        v3 = [line.split(" ")[3].split("/")[0].to_i, line.split(" ")[3].split("/")[1].to_i, line.split(" ")[3].split("/")[2].to_i]
        @f.push([v1, v2, v3])
      end
    end
    to_display_list
  end

  def to_display_list
    @list = glGenLists(1)
    glNewList(@list, GL_COMPILE)
    glBegin(GL_TRIANGLES)
    @f.each do |f|
      f.each do |point|
        glTexCoord2d(@vt[point[1] - 1][0], 1.0 - @vt[point[1] - 1][1])
        glNormal(@vn[point[2] - 1][0], @vn[point[2] - 1][1], @vn[point[2] - 1][2])
        glVertex3f(@v[point[0] - 1][0], @v[point[0] - 1][1], @v[point[0] - 1][2])
      end
    end
    glEnd
    glEndList
  end

  def draw(texture, x = 0.0, y = 0.0, z = 0.0, scale = 1.0, rot_x = 0.0, rot_y = 0.0, rot_z = 0.0)
    glPushMatrix
    glTranslate(x, y, z)
    glRotate(rot_x, 0, 1, 0)
    glRotate(rot_y, 1, 0, 0)
    glRotate(rot_z, 0, 0, 1)
    glScale(scale, scale, scale)
    glBindTexture(GL_TEXTURE_2D, texture.get_id)
    glCallList(@list)
    glPopMatrix
  end
end

class Box2D
  attr_accessor :origin, :width, :length
  def initialize(origin, width, length)
    @origin = origin
    @width, @length = width, length
  end

  def collides?(box)
    if (box.origin.x >= self.origin.x + self.width) # more right
      return false
    elsif (box.origin.x + box.width <= self.origin.x) # more left
      return false
    elsif (box.origin.z >= self.origin.z + self.length) # more front
      return false
    elsif (box.origin.z + box.length <= self.origin.z) # more back
      return false
    else
      return true
    end
  end
end

class Vector3D
  attr_accessor :x, :y, :z
  def initialize(x = 0.0, y = 0.0, z = 0.0)
    @x, @y, @z = x, y, z
  end

  def to_s
    return @x.round(2).to_s + "," + @y.round(2).to_s + "," + @z.round(2).to_s
  end
end

class Tile
  attr_reader :type, :x, :y, :z
  def initialize(map, type, texture, x, y, z, y_scale = 1.0, y_repeat = false)
    @map = map
    @type = type
    @texture = texture
    @x, @y, @z = x, y, z
    @y_scale = y_scale
    @y_repeat = y_repeat
  end

  def draw
    x, y, z = @x, @y, @z
    if @type == :floor
      glBindTexture(GL_TEXTURE_2D, @texture.get_id)
      glColor4f(1.0, 1.0, 1.0, 1.0)
      glPushMatrix
      glTranslate(x, y, z)
      glBegin(GL_QUADS)
        glTexCoord2d(0.0, 0.0); glVertex3f(0.0, 0.0, 0.0)
        glTexCoord2d(1.0, 0.0); glVertex3f(1.0, 0.0, 0.0)
        glTexCoord2d(1.0, 1.0); glVertex3f(1.0, 0.0, 1.0)
        glTexCoord2d(0.0, 1.0); glVertex3f(0.0, 0.0, 1.0)
      glEnd
      glPopMatrix

      # ROOF DRAWING
      glBindTexture(GL_TEXTURE_2D, @map.tiles[2].get_id)
      glColor4f(0.7, 0.7, 0.7, 0.7)
      glPushMatrix
      glTranslate(x, y + 5.0, z)
      glBegin(GL_QUADS)
        glTexCoord2d(0.0, 0.0); glVertex3f(0.0, 0.0, 0.0)
        glTexCoord2d(1.0, 0.0); glVertex3f(1.0, 0.0, 0.0)
        glTexCoord2d(1.0, 1.0); glVertex3f(1.0, 0.0, 1.0)
        glTexCoord2d(0.0, 1.0); glVertex3f(0.0, 0.0, 1.0)
      glEnd
      glPopMatrix
    elsif @type == :wall
      # here we have to get which of the 4 walls had to be drawn
      if @y_repeat
        glMatrixMode(GL_TEXTURE)
        glLoadIdentity
        glScale(1.0, @y_scale, 1.0)
        glMatrixMode(GL_MODELVIEW)
      end

      if @map.map[[x + 1, z]] != nil and @map.map[[x + 1, z]].type == :floor
        # RIGHT WALL
        glBindTexture(GL_TEXTURE_2D, @texture.get_id)
        glColor4f(0.7, 0.7, 0.7, 0.7)
        glPushMatrix
        glTranslate(x + 1.0, y, z)
        glScale(1.0, @y_scale, 1.0)
        glBegin(GL_QUADS)
          glTexCoord2d(0.0, 1.0); glVertex3f(0.0, 0.0, 0.0)
          glTexCoord2d(1.0, 1.0); glVertex3f(0.0, 0.0, 1.0)
          glTexCoord2d(1.0, 0.0); glVertex3f(0.0, 1.0, 1.0)
          glTexCoord2d(0.0, 0.0); glVertex3f(0.0, 1.0, 0.0)
        glEnd
        glPopMatrix
      end

      if @map.map[[x - 1, z]] != nil and @map.map[[x - 1, z]].type == :floor
        # LEFT WALL
        glBindTexture(GL_TEXTURE_2D, @texture.get_id)
        glColor4f(0.7, 0.7, 0.7, 0.7)
        glPushMatrix
        glTranslate(x, y, z)
        glScale(1.0, @y_scale, 1.0)
        glBegin(GL_QUADS)
          glTexCoord2d(0.0, 1.0); glVertex3f(0.0, 0.0, 0.0)
          glTexCoord2d(1.0, 1.0); glVertex3f(0.0, 0.0, 1.0)
          glTexCoord2d(1.0, 0.0); glVertex3f(0.0, 1.0, 1.0)
          glTexCoord2d(0.0, 0.0); glVertex3f(0.0, 1.0, 0.0)
        glEnd
        glPopMatrix
      end

      if @map.map[[x, z + 1]] != nil and @map.map[[x, z + 1]].type == :floor
        # FRONT WALL
        glBindTexture(GL_TEXTURE_2D, @texture.get_id)
        glColor4f(1.0, 1.0, 1.0, 1.0)
        glPushMatrix
        glTranslate(x, y, z + 1)
        glScale(1.0, @y_scale, 1.0)
        glBegin(GL_QUADS)
          glTexCoord2d(0.0, 1.0); glVertex3f(0.0, 0.0, 0.0)
          glTexCoord2d(1.0, 1.0); glVertex3f(1.0, 0.0, 0.0)
          glTexCoord2d(1.0, 0.0); glVertex3f(1.0, 1.0, 0.0)
          glTexCoord2d(0.0, 0.0); glVertex3f(0.0, 1.0, 0.0)
        glEnd
        glPopMatrix
      end

      if @map.map[[x, z - 1]] != nil and @map.map[[x, z - 1]].type == :floor
        # BACK WALL
        glBindTexture(GL_TEXTURE_2D, @texture.get_id)
        glColor4f(1.0, 1.0, 1.0, 1.0)
        glPushMatrix
        glTranslate(x, y, z)
        glScale(1.0, @y_scale, 1.0)
        glBegin(GL_QUADS)
          glTexCoord2d(0.0, 1.0); glVertex3f(0.0, 0.0, 0.0)
          glTexCoord2d(1.0, 1.0); glVertex3f(1.0, 0.0, 0.0)
          glTexCoord2d(1.0, 0.0); glVertex3f(1.0, 1.0, 0.0)
          glTexCoord2d(0.0, 0.0); glVertex3f(0.0, 1.0, 0.0)
        glEnd
        glPopMatrix
      end
    end
  end
end

class Map
  attr_reader :parent_window, :map, :tiles, :map_texture, :rect
  def initialize(parent_window, filename, tileset, walls_tileset, tile_size = 16, wall_height = 80)
    @parent_window = parent_window
    @map_texture = Gosu::Image.new(@parent_window, filename, true)
    @colors = Hash.new

    tiles = Gosu::Image.load_tiles(@parent_window, tileset, tile_size, tile_size, true)
    @tiles = Array.new
    for t in 0...tiles.size
      if t%2 == 0 # if this is a tile
        @tiles.push GLTexture.new(@parent_window, tiles[t])
        @colors[tiles[t + 1].get_rgb(0, 0)] = [:floor, @tiles.size - 1]
      end
    end

    walls = Gosu::Image.load_tiles(@parent_window, walls_tileset, tile_size, wall_height, true)
    @walls = Array.new
    for w in 0...walls.size
      walls[w].refresh_cache
      if w%2 == 0 # if this is a texture
        @walls.push GLTexture.new(@parent_window, walls[w])
        @colors[walls[w + 1].get_rgb(0, 0)] = [:wall, @walls.size - 1]
      end
    end

    @map = Hash.new
    @rect = Box2D.new(Vector3D.new(nil, 0, nil), nil, nil)
    @collisions = Hash.new
    read_map
  end

  def read_map
    y = 0 # we'll see later about that
    for z in 0...@map_texture.height
      for x in 0...@map_texture.width
        color = @map_texture.get_rgb(x, z)
        if color == [0, 0, 0]
          next # black color == invisibility
        else
          # first not nil tile encountered or lefter
          if @rect.origin.x == nil or x < @rect.origin.x
            @rect.origin.x = x
          end

          # first not nil tile encoutered or lower
          if @rect.origin.z == nil or z < @rect.origin.z
            @rect.origin.z = z
          end

          if @rect.width == nil or @rect.origin.x + @rect.width < x
            @rect.width =  x - @rect.origin.x
          end

          if @rect.length == nil or @rect.origin.z + @rect.length < z
            @rect.length =  z - @rect.origin.z
          end

          if @colors.has_key?(color)
            if @colors[color][0] == :floor
              @map[[x, z]] = Tile.new(self, :floor, @tiles[@colors[color][1]], x, y, z)
            elsif @colors[color][0] == :wall
              @map[[x, z]] = Tile.new(self, :wall, @walls[@colors[color][1]], x, y, z, 5.0, false)
              # collision detection optimization : horizontal contigus rectangles
              found = false
              for temp_x in 0...x
                if @collisions.has_key?([temp_x, z]) and temp_x + @collisions[[temp_x, z]].width == x
                  @collisions[[temp_x, z]].width += 1
                  found = true
                  break
                end
              end
              if !found # vertical contigus rectangles optimization
                for temp_z in 0...z
                  if @collisions.has_key?([x, temp_z]) and temp_z + @collisions[[x, temp_z]].length == z and @collisions[[x, temp_z]].width == 1
                    @collisions[[x, temp_z]].length += 1
                    found = true
                    break
                  end
                end
              end
              # if there was no possibility to extend a previous box vertically or horizontally, new box
              if !found
                @collisions[[x, z]] = Box2D.new(Vector3D.new(x, y, z), 1.0, 1.0)
              end
            end
          end
        end
      end
    end

    # starting from 0 fix
    @rect.width += 1
    @rect.length += 1
  end

  def block?(box2)
    @collisions.each_value do |box|
      if box.collides?(box2)
        return true
      end
    end
    return false # default
  end

  def draw
    glEnable(GL_TEXTURE_2D)
    @map.each do |coords, tile|
      tile.draw
    end
  end
end
