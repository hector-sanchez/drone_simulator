require './orientation_sensor.rb'

class Gyroscope
    def vectors
        @vectors ||= %i[x y z].map {|v| vector.new(v, 0) }
    end
    
    def velocify(direction, target_velocity)
        target_vector = vectors.find{|vector| vector.direction = direction }
        target_vector.adjust_velocity(target_velocity)
    end
    
    private
    
    def vector
        Struct.new(:direction, :velocity) do
            def adjust_velocity(target_velocity)
                if velocity < target_velocity
                    accelerate_to(target_velocity)
                else
                    deccelerate_to(target_velocity)
                end
            end
            
            private
    
            def orientation_sensor
                @orientation_sensor ||= OrientationSensor.new
            end
            
            def direction_predicate
                return orientation_sensor.pitch if direction == :y
                
                orientation_sensor.roll
            end
            
            def accelerate_to(target_velocity)
                velocity.upto(target_velocity) do |v|
                    self.velocity = v
                    puts "speeding up #{direction_predicate}...#{velocity} knots/sec"
                end
            end
            
            def deccelerate_to(target_velocity)
                target_velocity = [target_velocity, 0].max
                velocity.downto(target_velocity) do |v|
                    self.velocity = v
                    puts "speeding down  #{direction_predicate}...#{velocity} knots/sec"
                end
            end
        end
    end
end

