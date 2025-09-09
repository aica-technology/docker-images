package main

import (
    "encoding/json"
    "crypto/tls"
    "fmt"
    "net/http"
    "os"
    "path/filepath"
    "strings"
    "time"

    "github.com/santhosh-tekuri/jsonschema/v6"
    "gopkg.in/yaml.v3"
)

type HTTPURLLoader http.Client

func (l *HTTPURLLoader) Load(url string) (any, error) {
    client := (*http.Client)(l)
    resp, err := client.Get(url)
    if err != nil {
        return nil, err
    }
    if resp.StatusCode != http.StatusOK {
        _ = resp.Body.Close()
        return nil, fmt.Errorf("returned status code %d", resp.StatusCode)
    }
    defer resp.Body.Close()

    return jsonschema.UnmarshalJSON(resp.Body)
}

func newHTTPURLLoader(insecure bool) *HTTPURLLoader {
    httpLoader := HTTPURLLoader(http.Client{
        Timeout: 10 * time.Second,
    })
    if insecure {
        httpLoader.Transport = &http.Transport{
            TLSClientConfig: &tls.Config{InsecureSkipVerify: true},
        }
    }
    return &httpLoader
}

func main() {
    if len(os.Args) != 2 {
        fmt.Println("Program requires path to instance file as unique argument!")
        os.Exit(1)
        return
    }
    instanceFile := os.Args[1]
    instanceData, err := os.ReadFile(instanceFile)
    if err != nil {
        fmt.Printf("Error reading instance file '%s': %v\n", instanceFile, err)
        os.Exit(1)
        return
    }

    var instance map[string]interface{}
    ext := strings.ToLower(filepath.Ext(instanceFile))
    switch ext {
    case ".json":
        err = json.Unmarshal(instanceData, &instance)
    case ".yaml", ".yml":
        err = yaml.Unmarshal(instanceData, &instance)
    default:
        fmt.Printf("Unsupported file extension: %s\n", ext)
        os.Exit(1)
        return
    }
    if err != nil {
        fmt.Printf("Error unmarshalling instance: %v\n", err)
        os.Exit(1)
        return
    }

    var schemaURL string
    if url, ok := instance["$schema"].(string); ok {
        schemaURL = url
    } else {
        fmt.Println("No $schema tag found in the JSON data.")
        os.Exit(1)
        return
    }

    loader := jsonschema.SchemeURLLoader{
        "file":  jsonschema.FileLoader{},
        "http":  newHTTPURLLoader(false),
        "https": newHTTPURLLoader(false),
    }
    c := jsonschema.NewCompiler()
    c.UseLoader(loader)
    schema, err := c.Compile(schemaURL)
    if err != nil {
        fmt.Printf("Error compiling schema: %v\n", err)
        os.Exit(1)
        return
    }

    err = schema.Validate(instance)
    if err != nil {
        if vErrs, ok := err.(*jsonschema.ValidationError); ok {
            fmt.Println("JSON instance is not valid against the schema specified in $schema. Errors:")
            for _, vErr := range vErrs.Causes {
                fmt.Printf("- %s\n", vErr)
            }
            if len(vErrs.Causes) == 0 {
                fmt.Printf("- %s\n", vErrs)
            }
        } else {
            fmt.Printf("Validation error: %v\n", err)
        }
        os.Exit(1)
    }
}
