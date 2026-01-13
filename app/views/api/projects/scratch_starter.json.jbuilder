json.meta do
  json.vm "11.5.0"
  json.agent "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/139.0.0.0 Safari/537.36"
  json.semver "3.0.0"
end

json.targets do
  json.array! [
    {
      name: "Stage",
      lists: {},
      tempo: 60,
      blocks: {},
      sounds: [],
      volume: 100,
      isStage: true,
      comments: {},
      costumes: [
        {
          name: "backdrop1",
          md5ext: "cd21514d0531fdffb22204e0ec5ed84a.svg",
          assetId: "cd21514d0531fdffb22204e0ec5ed84a",
          dataFormat: "svg",
          rotationCenterX: 240,
          rotationCenterY: 180
        }
      ],
      variables: {
        "`jEk@4|i[#Fk?(8x)AV.-my variable": ["my variable", 0]
      },
      broadcasts: {},
      layerOrder: 0,
      videoState: "on",
      currentCostume: 0,
      videoTransparency: 50,
      textToSpeechLanguage: nil
    }
  ]
end

json.monitors []
json.extensions []