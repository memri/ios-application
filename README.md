# iOS application

The memri iOS application can be used to connect to your [pod](https://gitlab.memri.io/memri/pod) to browse and use your data.

### Developer

## formatter
```brew install nshipster/formulae/swift-format```

```[sudo] gem install jazzy```

## Run formatter
*make sure to run this from the repo directory only*
```swift-format . --configuration .swift-format.json```

## Defining your own interface
The iOS application uses Cascading Views for defining the interfaces in the app. If you are interested in making your own interface for your data, check out the [list of supported cvu definitions](https://gitlab.memri.io/memri/ios-application/-/wikis/List-of-supported-CVU-definitions) and the [cvu expression language](https://gitlab.memri.io/memri/ios-application/-/wikis/CVU-Expression-Language)
