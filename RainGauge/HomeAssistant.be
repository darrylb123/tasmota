var dev_string = "
{
  \"dev\": {
    \"ids\": "ea778860945cdc",
    \"name\": "Rain Gauge",
    \"mf\": "darrylb123",
    \"mdl\": "xya",
    \"sw\": "1.0",
    \"sn\": "ea334450945afc",
    \"hw\": "1.0rev2"
  },
  "o": {
    "name":"flipper",
    "sw": "2.1",
    "url": "https://bla2mqtt.example.com/support"
  },
  "device_class":"temperature",
  "unit_of_measurement":"°C",
  "value_template":"{{ value_json.temperature}}",
  "unique_id":"temp01ae_t",
  "state_topic":"sensorBedroom/state",
  "qos": 2
}
