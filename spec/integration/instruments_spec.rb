describe RunLoop::Instruments do

  let(:simctl) { Resources.shared.simctl }
  let(:instruments) { Resources.shared.instruments }
  let(:xcode) { Resources.shared.xcode }

  before(:each) do
    Resources.shared.kill_fake_instruments_process
    allow(RunLoop::Environment).to receive(:debug?).and_return(true)
  end

  describe '#kill_instruments' do

    let(:options) do
      {
            :app => Resources.shared.cal_app_bundle_path,
            :device_target => 'simulator',
            :simctl => simctl,
            :instruments => instruments,
            :xcode => xcode
      }
    end

    describe 'running against simulators' do
      it 'the current Xcode version' do
        Resources.shared.launch_with_options(options) do |hash|
          expect(hash).not_to be nil
          expect(instruments.instruments_running?).to be == true
          instruments.kill_instruments
          expect(instruments.instruments_running?).to be == false
        end
      end

      describe 'regression' do
        xcode_installs = Resources.shared.alt_xcode_install_paths
        if xcode_installs.empty?
          it 'no alternative versions of Xcode found' do
            expect(true).to be == true
          end
        else
          xcode_installs.each do |developer_dir|
            it "#{developer_dir}" do
              Resources.shared.with_developer_dir(developer_dir) do

                options[:simctl] = RunLoop::Simctl.new
                options[:instruments] = RunLoop::Instruments.new
                options[:xcode] = RunLoop::Xcode.new

                if xcode.version_gte_8?
                  RunLoop.log_debug("Skipping Xcode 8 instruments tests")
                else
                  Resources.shared.launch_with_options(options) do |hash|
                    expect(hash).not_to be nil
                    expect(instruments.instruments_running?).to be == true
                    instruments.kill_instruments
                    expect(instruments.instruments_running?).to be == false
                  end
                end
              end
            end
          end
        end
      end
    end
  end

  describe '#instruments_app_running?' do

    before(:each) { Resources.shared.kill_instruments_app }
    after(:each) { Resources.shared.kill_instruments_app }

    it 'returns true when Instruments.app is running' do
      Resources.shared.launch_instruments_app
      expect(instruments.instruments_app_running?).to be == true
    end

    it 'returns false when Instruments.app is not running' do
      Resources.shared.kill_instruments_app(instruments)
      expect(instruments.instruments_app_running?).to be == false
    end
  end

  describe '#pids_from_ps_output' do
    it 'when instruments process is running return 1 process' do
      simctl = Resources.shared.simctl
      options =
            {
                  :app => Resources.shared.cal_app_bundle_path,
                  :device_target => 'simulator',
                  :simctl => simctl
            }

      Resources.shared.launch_with_options(options) do |hash|
        expect(hash).not_to be nil
        expect(instruments.send(:pids_from_ps_output).count).to be == 1
      end
    end
  end
end
