RSpec.describe "stub_fixture" do
  subject { arguments.map { |argument| Payment.new.pay(argument) } }

  before do
    class Payment
      def pay(_)
        5
      end
    end
  end

  context "without stubbing" do
    let(:arguments) { [0] }

    it { is_expected.to eq [5] }
  end

  context "when message chain stubbed" do
    before { stub_fixture "#{__dir__}/stub.yml" }

    context "with a :raise option" do
      let(:arguments) { [0] }

      it "raises an exception" do
        expect { subject }.to raise_error do |ex|
          expect(ex).to be_kind_of(ArgumentError)
          expect(ex.message).to eq "Something got wrong"
        end
      end
    end

    context "with a :return option" do
      let(:arguments) { [1] }

      it "returns stubbed value" do
        expect(subject).to eq [8]
      end
    end

    context "with several actions" do
      let(:arguments) { [2] * 4 }

      it "calls the consecutive actions and then repeates the last one" do
        expect(subject).to eq [4, 2, 0, 0]
      end
    end

    context "with multi-count actions" do
      let(:arguments) { [3] * 4 }

      it "repeats the action a specified number of times" do
        expect(subject).to eq [6, 6, 0, 0]
      end
    end

    context "with several arguments" do
      let(:arguments) { [2, 3, 2, 3, 2, 3] }

      it "counts actions for every stub in isolation from the others" do
        expect(subject).to eq [4, 6, 2, 6, 0, 0]
      end
    end

    context "with partially defined options" do
      subject { Payment.new.pay(10, overdraft: true, notify: true) }

      it "uses the stub" do
        expect(subject).to eq(-5)
      end
    end

    context "when options differ" do
      subject { Payment.new.pay(10, overdraft: false) }

      it "uses universal stub" do
        expect(subject).to eq(-1)
      end
    end

    context "with unspecified argument" do
      let(:arguments) { [4] }

      it "uses universal stub" do
        expect(subject).to eq [-1]
      end
    end
  end

  context "when constant stubbed" do
    before do
      TIMEOUT = 20
      stub_fixture "#{__dir__}/stub.yml"
    end

    it "stubs the constant" do
      expect(TIMEOUT).to eq 10
    end
  end

  context "when ENV stubbed" do
    before do
      ENV["FOO"] = "foo"
      ENV["BAR"] = "bar"
      ENV["QUX"] = "qux"
      stub_fixture "#{__dir__}/stub.yml"
    end

    it "stubs the ENV" do
      expect(ENV["FOO"]).to eq "oof"
      expect(ENV["BAR"]).to eq "rab"
    end

    it "preserves unstubbed ENV" do
      expect(ENV["QUX"]).to eq "qux"
    end
  end

  context "when http request stubbed" do
    before { stub_fixture "#{__dir__}/stub.yml" }

    it "stubs the request properly" do
      req = Net::HTTP::Get.new("/foo")
      res = Net::HTTP.start("www.example.com") { |http| http.request(req) }

      expect(res.code).to eq "200"
      expect(res.body).to eq "foo"
      expect(res["Content-Length"]).to eq "3"
    end

    def delete_request
      req = Net::HTTP::Delete.new("/foo")
      Net::HTTP.start("www.example.com") { |http| http.request(req) }
    end

    it "stubs repetitive requests properly" do
      expect(delete_request.code).to eq "200"
      expect(delete_request.code).to eq "404"
      expect(delete_request.code).to eq "404"
    end
  end
end
