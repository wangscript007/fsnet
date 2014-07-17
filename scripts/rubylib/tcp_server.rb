require "tcp_pack.rb"
require "tcp_client.rb"


#_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/
# * TCP Server类
#-------------------------------------------------------------------------------------------------------
#
#     
#_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/
class GameTCPServer < FSServer
	
	
	class Scheduler
		
		attr_reader :sid
		attr_reader :server
		attr_reader :execute_proc
		def initialize()
			
		end
		def start(server, dt, times, execute_proc)
			
			@prote_proc = Proc.new do |dt|
				@execute_proc.call(dt / 1000000.0)
			end
			
			@execute_proc = execute_proc
			@server = server
			@sid = @server.scheduler(dt, times, @prote_proc)
		end
		def stop
			if(@sid != 0 and @server != nil)
				@server.unscheduler(@sid)
				@sid = 0
				@server = nil
			end
		end
		
	end
  
  # 所有客户端
  attr_reader :clients;
  attr_reader :byte_order
  
  
  def initialize(server_name)
     super(server_name);
     @clients = {}
     @byte_order = 0;
     @start_proc = nil;
  end
  
  
	def scheduler_update(dt, times, &proc)
		scheduler = Scheduler.new()
		scheduler.start(self, dt, times, proc)
		return scheduler
	end
  #_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/
  # * 开始服务
  #-------------------------------------------------------------------------------------------------------
  #     @ip     ip地址
  #     @port   端口
  #     @proc   开始后的回调
  #_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/
  def start_server(ip, port, &proc)
      super(ip, port, T_TCP);
      @start_proc = proc;
  end
  
  
  @@_start_time = Time.now.to_i;
  @@_times = 0;
  #_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/
  # * 收到包的时候的回调
  #-------------------------------------------------------------------------------------------------------
  #     @node_id    这个从哪个节点过来的
  #     @pack       pack
  #_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/
  def on_handle_pack(node_id, pack)
      @@_times += 1
			now = Time.now.to_i;
      if(now - @@_start_time > 0)
          print "#{self.name} handle packs #{@@_times}/#{now - @@_start_time}s \n"
          @@_start_time = now;
          @@_times = 0
      end
  end
  
  #_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/
  # * 当服务完成开启的回调
  #-------------------------------------------------------------------------------------------------------
  #
  #
  #_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/
  def on_start()
      if(@start_proc != nil)
          @start_proc.call(self);
      end
  end
  
  #_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/
  # * 当有新连接进来的时候
  #-------------------------------------------------------------------------------------------------------
  #     @node_id    新连接的节点ID
  #
  #_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/
  def on_connect_node(node_id)
      # p "#{self.name} new connect node_id:#{node_id}, say'it hello ";
      @clients[node_id] = TCPClient.new(self, node_id);
  end
  
  #_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/
  # * 当有连接关闭的时候
  #-------------------------------------------------------------------------------------------------------
  #     @node_id    关闭掉的节点ID
  #
  #_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/
  def on_shudown_node(node_id)
			@clients.delete(node_id)
      # p "#{self.name} shudown connect #{node_id}";
  end
 
  
  #_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/
  # * 向指定节点发送包
  #-------------------------------------------------------------------------------------------------------
  #     @node_id	目标节点ID
	#     @pack    要发送的包
  #_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/n_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/
  def send_pack_to(node_id, pack)
		if(@clients[node_id] != nil)
			@clients[node_id].send_pack(pack);
			return true
		end
		raise("#{self.name} send_pack_to target_id(#{node_id}) is NULL clients id => #{@clients.keys}")
		return false
  end


end
