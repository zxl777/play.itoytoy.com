God.watch do |w|
  w.name = "pm"
  w.start = "bash /home/power777888/mp1.5/start.sh"
  w.keepalive(:memory_max => 850.megabytes,
              :cpu_max => 80.percent)
end
