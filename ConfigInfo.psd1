#
# ConfigInfo.psd1
#
@{
	VersionInfo = @{
		gnuradio = '3.8.2.0' 
		volk = '2.3'
		openssl = '1.0.2r'
		UHD = '4.0.0.0'
		gqrx = '2.14.1'
		Cython = '0.28.5'
		numpy = '1.16.4'
		scipy = '1.2.2'
		lapack = '3.8.0'
		OpenBLAS  = '0.3.3'
		pyzmq = '17.1.2'
		libzmq = '4.3.1'
		cppzmq = '4.3.0'
		boost = '1.74.0'
		boost_ = '1_74_0'
		libpng = '1.6.37'
		qwt = '5.2.3'
		qwt6 = '6.1.4'
		SDL = '1.2.15'
		cppunit = '1.12.1'
		sip = '4.19.14'
		PyQt = '4.12.3'
		PyQt5 = '5.10.1'
		pyopengl = '3.1.0'
		py2cairo = '1.17.1'
		pyyaml = '3.13'
		cheetah = '2.4.4'
		gsl = '1.16'
		mpir = '3.0.0'
		pthreads = '2-9-1'
		libxml2 = '2.9.9'
		lxml = '3.6.0'
		libxslt = '1.1.29'
		pkgconfig = '1.1.0'
		log4cpp = '1.1.3'
		libusb = '1.0.22'   
		fftw = '3.3.6-pl2'      
		matplotlib = '2.0.0'
		PIL = '1.1.7'
		bitarray = '0.8.1'
		mbedtls = '2.4.2'
		openlte = '00-20-04'
		wxpython = '3.0.2.0'# Changing to 3.1+ will require other code changes
		pygobject = '2.28.6'# Changing to 2.29+ will require other code changes (but don't because 2.29 doesn't have the same setup.py)
		pygobject3 = '3.34.0'
		pygtk = '2.24'    # Changing to 2.25+ will require other code changes
		qt = '4.8.7'        # This isn't actually used.  4.8.7 is hardcoded but 4.8.7 is the last 4.x version to the change to Qt5 will change much more
		qt5 = '5.15.2'
		python = '3.7.7'  # 3.8 changes DLL search paths in a very unpleasant way for GTK
		dp = '1.6'        # dependency pack version
		# OOT modules
		bladerf = '2019.07'
		rtlsdr = '0.6.0'
		hackrf = 'v2018.01.1'
		airspy = 'v1.0.9'
		airspyhf = '1.6.8'
		freeSRP = '0.3.0'
		SoapySDR = '0.7.2'
		iqbal = '0.38.1'
		gr_osmosdr = '0.2.2'
		grdisplay = '3.8'  
		# TODO The following libraries are currently downloaded from current git snapshot.  This should be replaced by specific release tags
		# PyQwt (5.2.1, abandoned, no releases marked)
		# zlib (1.2.8 but should rarely change)
		# libsodium (but is forked on github.com/gnieboer/libsodium)
		
	}
	# While most of the GTK stack can be built internally, it was not 100% complete when hexchat's port using VS 2015 was discovered
	# which has already been more thoroughly tested, so while the already accomplished code is still in place,
	# it is disabled for the moment
	BuildGTKFromSource = $false
}