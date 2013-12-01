class TimeSeriesChart
  width: ->
    $(document).width()

  constructor: () ->
    el = "#usage-graphs"

    queues = []
    $(el).find('.queue').map ->
      queues.push($(this).data('name'))

    colors = ["","","","","rgba(0,0,0,0.05)","rgba(50,0,0,0.1)","rgba(150,0,0,0.2)","rgba(250,0,0,0.5"]

    @context = context = cubism.context()
        .step(1e3/2)
        .size(@width())

    d3.select(el).selectAll(".axis")
        .data(["top", "bottom"])
      .enter().append("div")
        .attr "class", (d) ->
          d + " axis"
        .each (d) ->
          d3.select(this).call(context.axis().ticks(12).orient(d))

    d3.select(el).append("div")
      .attr("class", "rule")
      .call(@context.rule())

    random = (label) =>
      value = 0
      values = []
      i = 0
      last = null

      metric = (start, stop, step, callback) ->
        start = +start
        stop = +stop;
        last ?= start

        while (last < stop)
          last += step
          value = Math.max(0, Math.min(10, value + .8 * Math.random() - .4 + .2 * Math.cos(i += 1.02)))
          values.push(value)

        callback(null, values = values.slice((start - stop) / step))

      @context.metric(metric, label)

    d3.select(el).selectAll(".horizon")
        .data(queues.map(random))
      .enter().insert("div", ".bottom")
        .attr("class", "horizon")
        .call(@context.horizon().extent([-10, 10]).colors(colors))

    @context.on "focus", (i) =>
      d3.selectAll(".value").style("right", i == null ? null : @context.size() - i + "px");

$ ->
  new TimeSeriesChart();
