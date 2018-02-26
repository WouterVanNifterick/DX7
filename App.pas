unit App;

interface
{
uses
  FMVoice, MIDI, Synth, SysexDX7, Visualizer, config, ;
var FMVoice = require('./voice-dx7');
var MIDI = require('./midi');
var Synth = require('./synth');
var SysexDX7 = require('./sysex-dx7');
var Visualizer = require('./visualizer');
var config = require('./config');
var defaultPresets = require('./default-presets');

const
  BUFFER_SIZE_MS = 1000 * config.bufferSize / config.sampleRate;
  MS_PER_SAMPLE = 1000 / config.sampleRate;
  VIZ_MODE_NONE = 0;
  VIZ_MODE_FFT = 1;
  VIZ_MODE_WAVE = 2;
  PARAM_START_MANIPULATION = 'param-start-manipulation';
  PARAM_STOP_MANIPULATION = 'param-stop-manipulation';
  PARAM_CHANGE = 'param-change';
  DEFAULT_PARAM_TEXT = '--';


// var app = Angular.module('synthApp', ['ngStorage']);
//var synth = new Synth(FMVoice, config.polyphony);
//var midi = new MIDI(synth);
//var audioContext = new (window.AudioContext || window.webkitAudioContext)();
//var visualizer = new Visualizer("analysis", 256, 35, 0xc0cf35, 0x2f3409, audioContext);
//var scriptProcessor = null;

function initializeAudio();
begin
	scriptProcessor = audioContext.createScriptProcessor(config.bufferSize, 0, 2);
	scriptProcessor.connect(audioContext.destination);
	scriptProcessor.connect(visualizer.getAudioNode());
	// Attach to window to avoid GC. http://sriku.org/blog/2013/01/30/taming-the-scriptprocessornode
	scriptProcessor.onaudioprocess = window.audioProcess = function (e) begin
		var buffer = e.outputBuffer;
		var outputL = buffer.getChannelData(0);
		var outputR = buffer.getChannelData(1);

		var sampleTime = performance.now() - BUFFER_SIZE_MS;

		for (var i = 0, length = buffer.length; i < length; i++) begin
			sampleTime += MS_PER_SAMPLE;
			if (synth.eventQueue.length && synth.eventQueue[0].receivedTime < sampleTime) begin
				synth.processMidiEvent(synth.eventQueue.shift());
			end;

			var output = synth.render();
			outputL[i] = output[0];
			outputR[i] = output[1];
		end;
	end;;
end;

// Polyphony counter
setInterval(function() begin
	var count = 0;
	synth.voices.map(function(voice) begin if (voice) count++; end;);
	if (count) console.log("Current polyphony:", count);
end;, 1000);

app.directive('toNumber', function() begin
	return begin
		require: 'ngModel',
		link: function (scope, elem, attrs, ctrl) begin
			ctrl.$parsers.push(function (value) begin
				return parseFloat(value || '');
			end;);
		end;
	end;;
end;);

app.filter('reverse', function() begin
	return function(items) begin
		return items ? items.slice().reverse() : items;
	end;;
end;);

app.directive('toggleButton', function() begin
	return begin
		restrict: 'E',
		replace: true,
		transclude: true,
		require: 'ngModel',
		scope: begin'ngModel': '='end;,
		template: '<button type="button" class="dx7-toggle ng-class:begin\'dx7-toggle-on\':ngModelend;" data-toggle="button" ng-click="ngModel = 1 - ngModel" ng-transclude></button>'
	end;;
end;);

app.directive('knob', function() begin
	function link(scope, element, attrs) begin
		var rotationRange = 300; // ±degrees
		var pixelRange = 200; // pixels between max and min
		var startY, startModel, down = false;
		var fgEl = element.find('div');
		var max = element.attr('max');
		var min = element.attr('min');
		var increment = (max - min) < 99 ? 1 : 2;
		element.on('mousedown', function(e) begin
			startY = e.clientY;
			startModel = scope.ngModel || 0;
			down = true;
			e.preventDefault();
			e.stopPropagation();
			window.addEventListener('mousemove', onMove);
			window.addEventListener('mouseup', onUp);
			element[0].querySelector('.knob').focus();
			scope.$emit(PARAM_START_MANIPULATION, scope.ngModel);
		end;);

		element.on('touchstart', function(e) begin
			if (e.touches.length > 1) begin
				// Don't interfere with any multitouch gestures
				onUp(e);
				return;
			end;

			startY = e.targetTouches[0].clientY;
			startModel = scope.ngModel || 0;
			down = true;
			e.preventDefault();
			e.stopPropagation();
			window.addEventListener('touchmove', onMove);
			window.addEventListener('touchend', onUp);
			element[0].querySelector('.knob').focus();
			scope.$emit(PARAM_START_MANIPULATION, scope.ngModel);
		end;);

		element.on('keydown', function(e) begin
			var code = e.keyCode;
			if (code >= 37 && code <= 40) begin
				e.preventDefault();
				e.stopPropagation();
				if (code == 38 || code == 39) begin
					scope.ngModel = Math.min(scope.ngModel + 1, max);
				end; else begin
					scope.ngModel = Math.max(scope.ngModel - 1, min);
				end;
				apply();
			end;
		end;);

		element.on('wheel', function(e) begin
			e.preventDefault();
			element[0].focus();
			if (e.deltaY > 0) begin
				scope.ngModel = Math.max(scope.ngModel - increment, min);
			end; else begin
				scope.ngModel = Math.min(scope.ngModel + increment, max);
			end;
			apply();
		end;);

		function onMove(e) begin
			if (down) begin
				var clientY = e.clientY;
				if (e.targetTouches && e.targetTouches[0])
					clientY = e.targetTouches[0].clientY;
				var dy = (startY - clientY) * (max - min) / pixelRange;
				// TODO: use 'step' attribute
				scope.ngModel = Math.round(Math.max(min, Math.min(max, dy + startModel)));
				apply();
			end;
		end;

		function onUp(e) begin
			down = false;
			window.removeEventListener('mousemove', onMove);
			window.removeEventListener('mouseup', onUp);
			window.removeEventListener('touchmove', onMove);
			window.removeEventListener('touchend', onUp);
			scope.$emit(PARAM_STOP_MANIPULATION, scope.ngModel);
		end;

		var apply = _.throttle(function () begin
			scope.$emit(PARAM_CHANGE, scope.label + ": " + scope.ngModel);
			scope.$apply();
		end;, 33);

		scope.getDegrees = function() begin
			return (this.ngModel - min) / (max - min) * rotationRange - (rotationRange / 2) ;
		end;
	end;

	return begin
		restrict: 'E',
		replace: true,
		require: 'ngModel',
		scope: beginngModel: '=', label: '@'end;,
		template: '<div><div class="param-label">beginbegin label end;end;</div><div class="knob" tabindex="0"><div class="knob-foreground" ng-style="begin\'transform\': \'rotate(\' + getDegrees() + \'deg)\'end;"></div></div></div>',
		link: link
	end;;
end;);

app.directive('slider', function() begin
	function link(scope, element, attrs) begin
		var sliderHandleHeight = 8;
		var sliderRailHeight = 50;
		var positionRange = sliderRailHeight - sliderHandleHeight;
		var pixelRange = 50;
		var startY, startModel, down = false;
		var max = element.attr('max');
		var min = element.attr('min');
		var increment = (max - min) < 99 ? 1 : 2;
		element.on('mousedown', function(e) begin
			startY = e.clientY;
			startModel = scope.ngModel || 0;
			down = true;
			e.preventDefault();
			e.stopPropagation();
			window.addEventListener('mousemove', onMove);
			window.addEventListener('mouseup', onUp);
			element[0].querySelector('.slider').focus();
			scope.$emit(PARAM_START_MANIPULATION, scope.ngModel);
		end;);

		element.on('touchstart', function(e) begin
			if (e.touches.length > 1) begin
				// Don't interfere with any multitouch gestures
				onUp(e);
				return;
			end;

			startY = e.targetTouches[0].clientY;
			startModel = scope.ngModel || 0;
			down = true;
			e.preventDefault();
			e.stopPropagation();
			window.addEventListener('touchmove', onMove);
			window.addEventListener('touchend', onUp);
			element[0].querySelector('.slider').focus();
			scope.$emit(PARAM_START_MANIPULATION, scope.ngModel);
		end;);

		element.on('keydown', function(e) begin
			var code = e.keyCode;
			if (code >= 37 && code <= 40) begin
				e.preventDefault();
				e.stopPropagation();
				if (code == 38 || code == 39) begin
					scope.ngModel = Math.min(scope.ngModel + 1, max);
				end; else begin
					scope.ngModel = Math.max(scope.ngModel - 1, min);
				end;
				apply();
			end;
		end;);

		element.on('wheel', function(e) begin
			e.preventDefault();
			element[0].querySelector('.slider').focus();
			if (e.deltaY > 0) begin
				scope.ngModel = Math.max(scope.ngModel - increment, min);
			end; else begin
				scope.ngModel = Math.min(scope.ngModel + increment, max);
			end;
			apply();
		end;);

		function onMove(e) begin
			if (down) begin
				var clientY = e.clientY;
				if (e.targetTouches && e.targetTouches[0])
					clientY = e.targetTouches[0].clientY;
				var dy = (startY - clientY) * (max - min) / pixelRange;
				scope.ngModel = Math.round(Math.max(min, Math.min(max, dy + startModel)));
				apply();
			end;
		end;

		function onUp(e) begin
			down = false;
			window.removeEventListener('mousemove', onMove);
			window.removeEventListener('mouseup', onUp);
			window.removeEventListener('touchmove', onMove);
			window.removeEventListener('touchend', onUp);
			scope.$emit(PARAM_STOP_MANIPULATION, scope.ngModel);
		end;

		var apply = _.throttle(function() begin
			scope.$emit(PARAM_CHANGE, scope.label + ": " + scope.ngModel);
			scope.$apply();
		end;, 33);

		scope.getTop = function() begin
			return positionRange - ((this.ngModel - min) / (max - min) * positionRange);
		end;
	end;

	return begin
		restrict: 'E',
		replace: true,
		require: 'ngModel',
		scope: beginngModel: '=', label: '@'end;,
		template: '<div><div class="slider" tabindex="0"><div class="slider-foreground" ng-style="begin\'top\': getTop() + \'px\'end;"></div></div><div class="slider-meter"></div></div>',
		link: link
	end;;
end;);

app.controller('MidiCtrl', ['$scope', '$http', function($scope, $http) begin
	// MIDI stuff
	var self = this;
	this.midiFileIndex = 0;
	this.midiFiles = [
		"midi/rachmaninoff-op39-no6.mid",
		"midi/minute_waltz.mid",
		"midi/bluebossa.mid",
		"midi/cantaloup.mid",
		"midi/chameleon.mid",
		"midi/tunisia.mid",
		"midi/sowhat.mid",
		"midi/got-a-match.mid"
	];
	this.midiPlayer = new MIDIPlayer(begin
		output: begin
			// Loopback MIDI to input handler.
			send: function(data, timestamp) begin
				//console.log("MIDI File Event:", data, timestamp);
				midi.send(begin data: data, receivedTime: timestamp end;);
			end;
		end;
	end;);

	this.onMidiPlay = function() begin
		$http.get(this.midiFiles[this.midiFileIndex], beginresponseType: "arraybuffer"end;)
			.success(function(data) begin
				console.log("Loaded %d bytes.", data.byteLength);
				var midiFile = new MIDIFile(data);
				self.midiPlayer.load(midiFile);
				self.midiPlayer.play(function() begin console.log("MIDI file playback ended."); end;);
			end;);
	end;;

	this.onMidiStop = function() begin
		this.midiPlayer.stop();
		synth.panic();
	end;;

	var mml = null;
	this.vizMode = 0;
	var mmlDemos = [ "t92 l8 o4 $" +
		"[>cg<cea]2.        [>cg<ceg]4" +
		"[>>a<a<c+fa+]2.    [>>a <a <c+ e a]4" +
		"[>>f <f g+ <c g]2. [>>f <f g+ <c f]4" +
		"[>>g <g g+ b <g+]2.[>>g <g <g]4;" +
		"t92 $ l1 o3 v12 r r r r2 r8 l32 v6 cdef v8 ga v10 b<c v12 de v14 fg;",
		"t120$ l8 o3    >g+2.. g+ a+4. a+ <c2 >a+    g+2.. a+4 a+4 <c4. >d+" +
			"              a+ g+2. g+ a+4. a+ <c2 >a+   g+2.. a+4 a+4 <c2.;" +
			"t120$l8 o4    rr g g4 g+ a+4 d4 d4 d+2     d c g g4 g+ a+4 d4 d4 d+2" +
			"              rr g g4 g+ a+4 d4 d4 d+2     d c g g4 g+ a+4 d4 d4 d+2.;" +
			"t120$l8 o4 v9 rr d+ d+2 r >a+4 a+4 <c2     >a+ g+ <d+ d+2 r >a+4 a+4 a+2" +
			"              rr d+ d+2 r >a+4 a+4 <c2     >a+ g+ <d+ d+2 r >a+4 a+4 a+2.;" +
			"t120$l8 o4 v8 rr c c2 r   >f4 f4 g2        a+ g+ <c c2 >f f4 r f g2<" +
			"              rr c c2 r   >f4 f4 g2        a+ g+ <c c2 >f f4 r f g2.<;"
	];
	var qwertyNotes = [];
	//Lower row: zsxdcvgbhnjm...
	qwertyNotes[16] = 41; // = F2
	qwertyNotes[65] = 42;
	qwertyNotes[90] = 43;
	qwertyNotes[83] = 44;
	qwertyNotes[88] = 45;
	qwertyNotes[68] = 46;
	qwertyNotes[67] = 47;
	qwertyNotes[86] = 48; // = C3
	qwertyNotes[71] = 49;
	qwertyNotes[66] = 50;
	qwertyNotes[72] = 51;
	qwertyNotes[78] = 52;
	qwertyNotes[77] = 53; // = F3
	qwertyNotes[75] = 54;
	qwertyNotes[188] = 55;
	qwertyNotes[76] = 56;
	qwertyNotes[190] = 57;
	qwertyNotes[186] = 58;
	qwertyNotes[191] = 59;

	// Upper row: q2w3er5t6y7u...
	qwertyNotes[81] = 60; // = C4 ("middle C")
	qwertyNotes[50] = 61;
	qwertyNotes[87] = 62;
	qwertyNotes[51] = 63;
	qwertyNotes[69] = 64;
	qwertyNotes[82] = 65; // = F4
	qwertyNotes[53] = 66;
	qwertyNotes[84] = 67;
	qwertyNotes[54] = 68;
	qwertyNotes[89] = 69;
	qwertyNotes[55] = 70;
	qwertyNotes[85] = 71;
	qwertyNotes[73] = 72; // = C5
	qwertyNotes[57] = 73;
	qwertyNotes[79] = 74;
	qwertyNotes[48] = 75;
	qwertyNotes[80] = 76;
	qwertyNotes[219] = 77; // = F5
	qwertyNotes[187] = 78;
	qwertyNotes[221] = 79;
	qwertyNotes[220] = 80;

	this.createMML = function (idx) begin
		var mml = new MMLEmitter(audioContext, mmlDemos[idx]);
		var noteHandler = function(e) begin
			synth.noteOn(e.midi, e.volume / 20);
			e.noteOff(function() begin
				synth.noteOff(e.midi);
			end;);
		end;;
		mml.tracks.map(function(track) begin track.on('note', noteHandler); end;);
		return mml;
	end;;

	this.onDemoClick = function(idx) begin
		if (mml && mml._ended == 0) begin
			mml.stop();
			synth.panic();
			mml = null;
		end; else begin
			mml = this.createMML(idx);
			mml.start();
		end;
	end;;

	this.onVizClick = function() begin
		this.vizMode = (this.vizMode + 1) % 3;
		switch (this.vizMode) begin
			case VIZ_MODE_NONE:
				visualizer.disable();
				break;
			case VIZ_MODE_FFT:
				visualizer.enable();
				visualizer.setModeFFT();
				break;
			case VIZ_MODE_WAVE:
				visualizer.enable();
				visualizer.setModeWave();
				break;
		end;
	end;;

	this.onKeyDown = function(ev) begin
		var note = qwertyNotes[ev.keyCode];
		if (ev.metaKey) return false;
		if (ev.keyCode == 32) begin
			synth.panic();
			ev.stopPropagation();
			ev.preventDefault();
			return false;
		end;
		if (note) begin
			if (!ev.repeat) begin
				synth.noteOn(note, 0.8 + (ev.ctrlKey ? 0.47 : 0));
			end;
			ev.stopPropagation();
			ev.preventDefault();
		end;
		return false;
	end;;

	this.onKeyUp = function(ev) begin
		var note = qwertyNotes[ev.keyCode];
		if (note)
			synth.noteOff(note);
		return false;
	end;;

	window.addEventListener('keydown', this.onKeyDown, false);
	window.addEventListener('keyup', this.onKeyUp, false);
end;]);

app.controller('OperatorCtrl', function($scope) begin
	$scope.$watchGroup(['operator.oscMode', 'operator.freqCoarse', 'operator.freqFine', 'operator.detune'], function() begin
		FMVoice.updateFrequency($scope.operator.idx);
		$scope.freqDisplay = $scope.operator.oscMode === 0 ?
			parseFloat($scope.operator.freqRatio).toFixed(2).toString() :
			$scope.operator.freqFixed.toString().substr(0,4).replace(/\.$/,'');
	end;);
	$scope.$watch('operator.volume', function() begin
		FMVoice.setOutputLevel($scope.operator.idx, $scope.operator.volume);
	end;);
	$scope.$watch('operator.pan', function() begin
		FMVoice.setPan($scope.operator.idx, $scope.operator.pan);
	end;);
end;);

app.controller('PresetCtrl', ['$scope', '$localStorage', '$http', function ($scope, $localStorage, $http) begin
	var self = this;

	this.lfoWaveformOptions = [ 'Triangle', 'Saw Down', 'Saw Up', 'Square', 'Sine', 'Sample & Hold' ];
	this.presets = defaultPresets;
	this.selectedIndex = 0;
	this.paramDisplayText = DEFAULT_PARAM_TEXT;

	var paramManipulating = false;
	var paramDisplayTimer = null;

	function flashParam(value) begin
		self.paramDisplayText = value;
		clearTimeout(paramDisplayTimer);
		if (!paramManipulating) begin
			paramDisplayTimer = setTimeout(function() begin
				self.paramDisplayText = DEFAULT_PARAM_TEXT;
				$scope.$apply();
			end;, 1500);
		end;
	end;

	$scope.$on(PARAM_START_MANIPULATION, function(e, value) begin
		paramManipulating = true;
		flashParam(value);
	end;);

	$scope.$on(PARAM_STOP_MANIPULATION, function(e, value) begin
		paramManipulating = false;
		flashParam(value);
	end;);

	$scope.$on(PARAM_CHANGE, function(e, value) begin
		flashParam(value);
	end;);

	$http.get('roms/ROM1A.SYX')
		.success(function(data) begin
			self.basePresets = SysexDX7.loadBank(data);
			self.$storage = $localStorage;
			self.presets = [];
			for (var i = 0; i < self.basePresets.length; i++) begin
				if (self.$storage[i]) begin
					self.presets[i] = Angular.copy(self.$storage[i]);
				end; else begin
					self.presets[i] = Angular.copy(self.basePresets[i]);
				end;
			end;
			self.selectedIndex = 10; // Select E.PIANO 1
			self.onChange();
		end;);

	this.onChange = function() begin
		this.params = this.presets[this.selectedIndex];
		FMVoice.setParams(this.params);
		// TODO: separate UI parameters from internal synth parameters
		// TODO: better initialization of computed parameters
		for (var i = 0; i < this.params.operators.length; i++) begin
			var op = this.params.operators[i];
			FMVoice.setOutputLevel(i, op.volume);
			FMVoice.updateFrequency(i);
			FMVoice.setPan(i, op.pan);
		end;
		FMVoice.setFeedback(this.params.feedback);
	end;;

	this.save = function() begin
		this.$storage[this.selectedIndex] = Angular.copy(this.presets[this.selectedIndex]);
		console.log("Saved preset %s.", this.presets[this.selectedIndex].name);
	end;;

	this.reset = function() begin
		if (confirm('Are you sure you want to reset this patch?')) begin
			delete this.$storage[this.selectedIndex];
			console.log("Reset preset %s.", this.presets[this.selectedIndex].name);
			this.presets[this.selectedIndex] = Angular.copy(self.basePresets[this.selectedIndex]);
			this.onChange();
		end;
	end;;

	$scope.$watch('presetCtrl.params.feedback', function(newValue) begin
		if (newValue !== undefined) begin
			FMVoice.setFeedback(self.params.feedback);
		end;
	end;);

	$scope.$watchGroup([
		'presetCtrl.params.lfoSpeed',
		'presetCtrl.params.lfoDelay',
		'presetCtrl.params.lfoAmpModDepth',
		'presetCtrl.params.lfoPitchModDepth',
		'presetCtrl.params.lfoPitchModSens',
		'presetCtrl.params.lfoWaveform'
	], function() begin
		FMVoice.updateLFO();
	end;);

	self.onChange();

  // Dirty iOS audio workaround. Sound can only be enabled in a touch handler.
	if /iPad|iPhone|iPod/.test(navigator.platform) then
  begin
		window.addEventListener("touchend", iOSUnlockSound, false);
		function iOSUnlockSound() begin
			window.removeEventListener("touchend", iOSUnlockSound, false);
			var buffer = audioContext.createBuffer(1, 1, 22050);
			var source = audioContext.createBufferSource();
			source.buffer = buffer;
			source.connect(audioContext.destination);
			if(source.play)begin source.play(0); end; else if(source.noteOn)begin source.noteOn(0); end;
			flashParam("Starting audio...");
			initializeAudio();
		end;
	end; else begin
		initializeAudio();
	end;

end;]);
}

implementation

end.
