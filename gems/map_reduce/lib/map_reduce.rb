module Kernel
	def map_reduce(task_list, thread_count, show_progress=false)
		task_count = task_list.size
		done_count = 0
		mutex = Mutex.new if show_progress
		thread_array = []
		thread_count = [task_count, thread_count].min
		thread_count.times do |i|
			thread_array << Thread.start(i) do |offset|
				index = offset
				while index < task_count
					task_list[index] = yield task_list[index]
					index += thread_count
					mutex.synchronize do
						done_count += 1
						puts "#{done_count}/#{task_count}"
					end if show_progress
				end
			end
		end
		thread_array.each do |thread| thread.join end
	end
end