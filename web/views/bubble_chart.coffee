class BubbleChart
  constructor: (data) ->
    @data = data
    @width = $(window).innerWidth() - 250;
    @height = $(window).innerHeight()

    @inspector = $('#inspector')
    @inspector.height( @height );
    #@tooltip = CustomTooltip("tooltip", 0)

    # locations the nodes will move towards
    # depending on which view is currently being
    # used
    @center = {x: @width / 2, y: @height / 2}
    @status_centers = {
      "enqueued": {x: @width / 3, y: @height / 2},
      "busy": {x: @width / 2, y: @height / 2},
      "success": {x: 2 * @width / 3, y: (@height / 8) * 3.5},
      "failed": {x: 2 * @width / 3, y: (@height / 8) * 4.5}
    }

    # used when setting up force and
    # moving around nodes
    @layout_gravity = -0.04
    @damper = 0.1

    # these will be set in create_nodes and create_bubbles
    @bubbles = null

    @nodes = []
    @force = null
    @circles = null
    @statuses = null

    @radius = 4+(@width*@height) / Math.pow(@data.length, 3)

    @status_nodes = [
      {type: 'label', id: -1, radius: 36, status: 'enqueued', x: @status_centers['enqueued']['x'], y: @status_centers['enqueued']['y']},
      {type: 'label', id: -2, radius: 36, status: 'busy', x: @status_centers['busy']['x'], y: @status_centers['busy']['y']},
      {type: 'label', id: -3, radius: 36, status: 'success', x: @status_centers['success']['x'], y: @status_centers['success']['y']},
      {type: 'label', id: -4, radius: 36, status: 'failed', x: @status_centers['failed']['x'], y: @status_centers['failed']['y']}
    ]

    this.create_nodes()
    this.create_bubbles()
    setTimeout(this.move_one, 500)

  move_one: () =>
    console.log("UPD!")
    for num in [1..2]
      node = @nodes[parseInt(Math.random()*1000)]
      if node.status == 'enqueued'
        node.status = 'busy'
      else if node.status == 'busy'
        node.status = ['failed', 'success'][parseInt(Math.random()*2)]

    @all_gs = @bubbles.selectAll("g")
      .data(@nodes, (d) -> d.id)

    @gs.selectAll("circle.job")
        .attr("class", (d) => d.type + " " + d.status)

    @display_by_status()
    setTimeout(this.move_one, 500)

  # create node objects from original data
  # that will serve as the data behind each
  # bubble in the bubbles, then add each node
  # to @nodes to be used later
  create_nodes: () =>
    @counts = {}
    @data.forEach (d) =>
      node =
        id: d.id
        radius: @radius
        queue: d.queue
        worker: d.worker
        params: d.params
        status: d.status
        type: 'job'
      @counts[d.status] ?= 0
      @counts[d.status]++
      @nodes.push node

    @status_nodes.forEach (node) =>
      @nodes.push node

  create_bubbles: () =>
    @bubbles = d3.select("#bubbles").append("svg")
      .attr("class", "bubbles")
      .attr("width", @width)
      .attr("height", @height)
      #.attr("id", "svg_bubbles")

    @all_gs = @bubbles.selectAll("g")
      .data(@nodes, (d) -> d.id)
    #@statuses = @bubbles.selectAll("text")
      #.data(@status_nodes, (d) -> d.status)

    @gs = @all_gs.enter().append("g")
      .attr("class", (d) => d.type)

    @circles = @gs
      .append("circle")
        .attr("r", (d) => d.radius)
        .attr("class", (d) => d.type)

    @gs.selectAll("circle.job")
        .attr("class", (d) => d.type + " " + d.status)
        #.attr("stroke-width", 2)
        #.attr("stroke", (d) => 'rgba(0,0,0,0.01)')
        .attr("id", (d) -> "bubble_#{d.id}")
        .on("mouseover", (d,i) -> that.show_details(d,i,this))
        .on("mouseout", (d,i) -> that.hide_details(d,i,this))

    @texts = @gs.filter('.label').append("text")
      .text((d) => d.status)
      .attr("text-anchor", "middle")
      #.attr("fill", "rgba(0,0,0,0.6)")
      .attr("y", 20)

    @texts = @gs.filter('.label').append("text")
      .attr("class", "count")
      .text((d) => @counts[d.status])
      .attr("text-anchor", "middle")
      #.attr("fill", "rgba(0,0,0,0.6)")
      .attr("y", 0)

      #.attr("x", (d) => @status_centers[d.status]['x'] )
      #.attr("y", (d) => @status_centers[d.status]['y'] )

    #@circles.push circle

    # used because we need 'this' in the
    # mouse callbacks
    that = this

    # radius will be set to 0 initially.
    # see transition below
    #@circles.enter()
      #.append("circle")
        #.attr("r", 0)
        #.attr("fill", (d) => @fill_color(d.status))
        #.attr("stroke-width", 2)
        #.attr("stroke", (d) => 'rgba(0,0,0,0.05)')
        ##.attr("id", (d) -> "bubble_#{d.id}")
        #.on("mouseover", (d,i) -> that.show_details(d,i,this))
        #.on("mouseout", (d,i) -> that.hide_details(d,i,this))
        #.append("text")
          #.text("h")
          #.attr("text-anchor", "middle")
          #.attr("stroke", (d) => 'rgba(0,0,0,0.05)')


    #@circles.enter().append("text")
      #.attr("class", "status")
      #.attr("x", (d) => statuses_x[d] )
      #.attr("y", 40)
      #.attr("text-anchor", "middle")
      #.text((d) -> d)

    # Fancy transition to make bubbles appear, ending with the
    # correct radius
    #@gs.transition().duration(1000).attr("r", (d) -> d.radius)


  # Charge function that is called for each node.
  # Charge is proportional to the diameter of the
  # circle (which is stored in the radius attribute
  # of the circle's associated data.
  # This is done to allow for accurate collision
  # detection with nodes of different sizes.
  # Charge is negative because we want nodes to
  # repel.
  # Dividing by 8 scales down the charge to be
  # appropriate for the visualization dimensions.
  charge: (d) ->
    -Math.pow(d.radius, 2.0) / 8

  # Starts up the force layout with
  # the default values
  start: () =>
    @force = d3.layout.force()
      .nodes(@nodes)
      .size([@width, @height])

  # Sets up force layout to display
  # all nodes in one circle.
  display_group_all: () =>
    @force.gravity(@layout_gravity)
      .charge(this.charge)
      .friction(0.9)
      .on "tick", (e) =>
        @circles.each(this.move_towards_center(e.alpha))
          .attr("cx", (d) -> d.x)
          .attr("cy", (d) -> d.y)
    @force.start()

    this.hide_statuses()

  # Moves all circles towards the @center
  # of the visualization
  move_towards_center: (alpha) =>
    (d) =>
      d.x = d.x + (@center.x - d.x) * (@damper + 0.02) * alpha
      d.y = d.y + (@center.y - d.y) * (@damper + 0.02) * alpha

  display_by_status: () =>
    #this.display_statuses()
    @force.gravity(@layout_gravity)
      .charge(this.charge)
      .friction(0.9)
      .on "tick", (e) =>
        @gs.each(this.move_towards_status(e.alpha))
          .attr("x", (d) -> d.x)
          .attr("y", (d) -> d.y)
          .attr "transform", (d) =>
            "translate("+d.x+","+d.y+")"

        #@texts.each(this.move_towards_status(e.alpha))
          #.attr("x", (d) -> d.x)
          #.attr("y", (d) -> d.y)


    @force.start()


  move_text_towards_status: (alpha) =>
    (d) =>

      target = {x: 100, y: 100}
      #@status_centers[d.status]
      d.x ?= 0
      d.y ?= 0
      d.x = d.x + (target.x - d.x) * (@damper + 0.02) * alpha * 1.1
      d.y = d.y + (target.y - d.y) * (@damper + 0.02) * alpha * 1.1


  # move all circles to their associated @status_centers
  move_towards_status: (alpha) =>
    (d) =>

      target = @status_centers[d.status]
      #target = {x: 500, y: 200}
      d.x ?= 0
      d.y ?= 0

      d.x = d.x + (target.x - d.x) * (@damper + 0.02) * alpha * 1.1
      d.y = d.y + (target.y - d.y) * (@damper + 0.02) * alpha * 1.1


  hide_statuses: () =>
    status = @bubbles.selectAll(".status").remove()

  show_details: (data, i, element) =>
    d3.select(element).attr("stroke", "rgba(0,0,0,0.3)")
    content = "<dl>" +
                "<dt>Queue:</dt><dd> #{data.queue}</dd>" +
                "<dt>Worker:</dt><dd> #{data.worker}</dd>" +
                "<dt>Status:</dt><dd> #{data.status}</dd>" +
                "<dt>Params:</dt><dd> #{data.params}</dd>" +
              "</dl>"

    @inspector.html(content)
    #content +="<span class=\"name\">Amount:</span><span class=\"value\"> $#{data.value}</span><br/>"
    #@tooltip.showTooltip(content,d3.event)


  hide_details: (data, i, element) =>
    d3.select(element).attr("stroke", "rgba(0,0,0,0.05)")
    @tooltip.hideTooltip()


root = exports ? this

$ ->
  chart = null

  render = (csv) ->
    chart = new BubbleChart csv
    chart.start()
    #root.display_group_all()
    root.display_by_status()

  root.display_group_all = () =>
    chart.display_group_all()

  root.display_by_status = () =>
    chart.display_by_status()

  root.display_by_queue = () =>
    chart.display_by_queue()

  root.display_by_worker = () =>
    chart.display_by_worker()


  #root.toggle_view = (view_type) =>
    #else
      #root.display_all()

  d3.csv "jobs.csv", render

