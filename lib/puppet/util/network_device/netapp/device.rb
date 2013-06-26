require 'puppet/util/network_device/netapp/facts'
require 'puppet/util/network_device/netapp/NaServer'
require 'uri'

class Puppet::Util::NetworkDevice::Netapp::Device

  attr_accessor :url, :transport, :vfiler
  
  def initialize(url, option = {})

    @url = URI.parse(url)

    if @url.path == '' or @url.path == '/'
      @vfiler = nil
    else
      @vfiler = /\/(.*)/.match(@url.path).captures[0]
    end

    raise Pupper::Error, "you have to define a username for filer #{@url.host}" unless @url.user
    raise Pupper::Error, "you have to define a password for filer #{@url.host}" unless @url.password
    raise Pupper::Error, "schema must be https right now" unless @url.scheme == 'https'

    @transport ||= NaServer.new(@url.host, 1, 13)
    @transport.set_admin_user(@url.user, @url.password)
    if @url.scheme == 'https'
      @transport.set_transport_type("HTTPS")
    end
    if @vfiler
      @transport.set_vfiler(@vfiler)
    end
    
    # Test interface
    result = @transport.invoke("system-get-version")
    if(result.results_errno() != 0)
      r = result.results_reason()
      raise Puppet::Error, "Puppet::Device::Netapp: invoke system-get-version failed : \n #{r} \n"
    else
      version = result.child_get_string("version")
      Puppet.debug("Puppet::Device::Netapp: Verion = #{version}")
    end
   end
		
  def facts
    @facts ||= Puppet::Util::NetworkDevice::Netapp::Facts.new(@transport)
    facts = @facts.retreive
    facts['vfiler'] = @vfiler if @vfiler
    facts
  end

end
