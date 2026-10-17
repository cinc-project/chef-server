
require "omnibus_ctl_helper"

module Omnibus
  class Ctl
    def credentials
      # This is defined in chef-server-ctl, but chef-server-ctl isn't
      # actually loaded as part of these tests and attempting to load
      # it would require some code changes since it expects to be able
      # to run the command specified in ARGV.
    end
  end
end

describe "chef-server-ctl maintenance" do

  let(:command) { "maintenance" }
  let(:running_config) { { "private_chef" => { "redis_lb" => { "vip" => "127.0.0.1", "port" => "16379" } } } }
  let(:veil_creds) do
    double("ChefSecretsFile", save: true)
  end

  before do
    @helper = OmnibusCtlHelper.new(["./plugins/maintenance.rb"])
    allow(@helper.ctl).to receive(:running_config).and_return(running_config)
    allow(@helper.ctl).to receive(:credentials).and_return(veil_creds)
    allow(veil_creds).to receive(:save)
  end

  context "when an invalid argument is passed" do
    it "should return a proper error" do
      expect { @helper.run_test_omnibus_command(command, []) }
        .to raise_error(SystemExit) { |e| expect(e.status).to eq(1) }
    end
  end

  context "when talking to redis" do
    let(:redis) { double("Redis") }

    before do
      allow(veil_creds).to receive(:get).with("redis_lb", "password").and_return("secret")
      allow(Redis).to receive(:new)
        .with(port: "16379", host: "127.0.0.1", username: "default", password: "secret")
        .and_return(redis)
    end

    it "enables maintenance mode with a string value" do
      expect(redis).to receive(:hset).with("dl_default", "503_mode", "true")
      @helper.run_test_omnibus_command(command, ["on"])
    end

    it "disables maintenance mode" do
      expect(redis).to receive(:hdel).with("dl_default", "503_mode")
      @helper.run_test_omnibus_command(command, ["off"])
    end

    it "adds an IP to the allowed set" do
      expect(redis).to receive(:sadd).with("xmaint_allowed_ips_list", "192.0.2.10")
      @helper.run_test_omnibus_command(command, ["-a", "192.0.2.10"])
    end

    it "removes an IP from the allowed set" do
      expect(redis).to receive(:srem).with("xmaint_allowed_ips_list", "192.0.2.10")
      @helper.run_test_omnibus_command(command, ["-r", "192.0.2.10"])
    end

    it "lists the allowed set" do
      expect(redis).to receive(:smembers).with("xmaint_allowed_ips_list").and_return(["127.0.0.1"])
      @helper.run_test_omnibus_command(command, ["-l"])
    end
  end

end