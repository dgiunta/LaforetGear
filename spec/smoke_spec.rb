require File.join(File.expand_path(File.dirname(__FILE__)), 'spec_helper')

describe "smoke test" do
	include Url

	URLS = [
		{	:name => 'B&H Photo', :price => '$2,499.00',
			:url => 'http://www.bhphotovideo.com/c/product/583953-REG/Canon_2764B003_EOS_5D_Mark_II.html' },

		{	:name => 'Red Rock Micro', :price => '$152.50',
			:url => 'http://store.redrockmicro.com/Catalog/DSLR-Counter-Balance/microBalance-counterweight-Starter-Kit' },

		{	:name => 'Manfrotto', :price => '$100.00',
			:url => 'http://www.manfrotto.us/product/241FB' },

		{	:name => 'Glidecam', :price => '$399.00',
			:url => 'http://www.glidecam.com/product-hd-series.php' },

		{	:name => 'Singular Software', :price => '$149',
			:url => 'http://www.singularsoftware.com/pluraleyes.html' },

		#{	:name => 'Lexar', :price => '',
			#:url => '' },

		{	:name => 'Canon USA', :price => '$2,359.00',
			:url => 'http://www.usa.canon.com/cusa/support/consumer/eos_slr_camera_systems/lenses/ef_14mm_f_2_8l_ii_usm' },

		{	:name => 'Cinevate', :price => '$945.00',
			:url => 'http://www.cinevate.com/catalog/product_info.php?products_id=109' },

		{	:name => 'Pelican Case', :price => '$239.95',
			:url => 'http://www.pelican-case.com/1650.html' },

		{	:name => 'Sennheiser USA', :price => '$1,199.99',
			:url => 'http://www.sennheiserusa.com/professional_wireless-microphone-systems_plug-on-transmitter_503110' },

		{	:name => 'Zacuto', :price => '$428.00',
			:url => 'http://store.zacuto.com/zonitor-handheld-kit-for-15mm-rods-or-19mm-rods.html' }
	]

	context "price selectors still work" do
		URLS.each do |site|
			it "on #{site[:name]}" do
				price_from(site[:url]).should == site[:price]
			end
		end
	end

	context "gear page structure is as expected" do
		before do
			@doc = Nokogiri::HTML(open('http://blog.vincentlaforet.com/mygear/cameras/'))
		end

		it "has a page-title h1" do
			@doc.css('.page-title h1').length.should == 1
		end

		it "has at least one B&H photo link inside of a table inside of the .post-body" do
			@doc.css('.post-body table tr a').map { |a| a.content }.should include('B&H')
		end
	end
end
