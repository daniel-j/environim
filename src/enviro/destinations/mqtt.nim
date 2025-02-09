import std/strformat
import picostdlib/net/mqttclient
import ../common

const MQTT_HOST {.strdefine.} = "test.mosquitto.org"
const MQTT_PORT {.intdefine.} = 8883
const MQTT_USE_TLS {.booldefine.} = true

const MQTT_USER {.strdefine.} = ""
const MQTT_PASS {.strdefine.} = ""

const MQTT_TOPIC {.strdefine.} = "enviro/{nickname}"

var client: MqttClient

proc connectToMqtt*(clientId: string; topic: string) =
  echo "connecting mqtt"
  client = newMqttClient()

  let clientConfig = MqttClientConfig(
    clientId: clientId,
    user: MQTT_USER,
    password: MQTT_PASS,
    keepAlive: 60,
    tls: MQTT_USE_TLS
  )

  client.setConnectionCallback(proc (connStatus: MqttConnectionStatusT) =
    if connStatus == MqttConnectionStatusT.MqttConnectAccepted:
      echo "connected!"

      #discard client.subscribe(topic, Qos0)
      #client.setConnectionCallback(nil)
      #client.disconnect()
      #client = nil # client is destroyed here
    else:
      echo "couldnt connect! status: " & $connStatus
      client = nil
  )

  # client.setInpubCallback(proc (topic: string; payload: string) =
  #   echo "got topic " & topic
  #   echo "got payload:"
  #   echo payload

  #   # client.setConnectionCallback(nil)
  #   # client.setInpubCallback(nil)
  #   # client.disconnect()
  #   # client = nil # client is destroyed here
  # )

  echo "connecting to mqtt ", MQTT_HOST, ":", MQTT_PORT

  if client.connect(MQTT_HOST, Port(MQTT_PORT), clientConfig):
    echo "connecting..."
  else:
    echo "failed to connect to mqtt server"
    client = nil
    return

  

proc uploadReadingMqtt*(clientId: string; nickname: string; reading: string) =
  let topic = fmt(MQTT_TOPIC)
  if client.isNil: connectToMqtt(clientId, topic)
  if client.isNil: return

  echo "publish = ", client.publish(topic, reading, Qos0, retain = true)
