// Match width of graphs with summary bar
$.getJSON($("#history").data("update-url"), function(data) {

var updateStatsSummary = function(data) {
  $('ul.summary li.processed span.count').html(data.processed.numberWithDelimiter())
  $('ul.summary li.failed span.count').html(data.failed.numberWithDelimiter())
  $('ul.summary li.busy span.count').html(data.busy.numberWithDelimiter())
  $('ul.summary li.scheduled span.count').html(data.scheduled.numberWithDelimiter())
  $('ul.summary li.retries span.count').html(data.retries.numberWithDelimiter())
  $('ul.summary li.enqueued span.count').html(data.enqueued.numberWithDelimiter())
}

var updateRedisStats = function(data) {
  $('.stat h3.redis_version').html(data.redis_version)
  $('.stat h3.uptime_in_days').html(data.uptime_in_days)
  $('.stat h3.connected_clients').html(data.connected_clients)
  $('.stat h3.used_memory_human').html(data.used_memory_human)
  $('.stat h3.used_memory_peak_human').html(data.used_memory_peak_human)
}

var pulseBeacon = function(){
  $beacon = $('.beacon')
  $beacon.find('.dot').addClass('pulse').delay(1000).queue(function(){
    $(this).removeClass('pulse');
    $(this).dequeue();
  });
  $beacon.find('.ring').addClass('pulse').delay(1000).queue(function(){
    $(this).removeClass('pulse');
    $(this).dequeue();
  });
}

Number.prototype.numberWithDelimiter = function(delimiter) {
  var number = this + '', delimiter = delimiter || ',';
  var split = number.split('.');
  split[0] = split[0].replace(
      /(\d)(?=(\d\d\d)+(?!\d))/g,
      '$1' + delimiter
  );
  return split.join('.');
};

// Render graphs
var renderGraphs = function() {
  realtimeGraph();
  historyGraph();
};

$(function(){
  renderGraphs();
});

// Reset graphs
var resetGraphs = function() {
  document.getElementById('realtime').innerHTML = '';
  document.getElementById('history').innerHTML = '';
};

// Resize graphs after resizing window
var debounce = function(fn, timeout)
{
  var timeoutID = -1;
  return function() {
    if (timeoutID > -1) {
      window.clearTimeout(timeoutID);
    }
    timeoutID = window.setTimeout(fn, timeout);
  }
};

window.onresize = debounce(function() {
    resetGraphs();
    renderGraphs();
}, 125);
