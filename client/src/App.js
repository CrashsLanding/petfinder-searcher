import React, { Component } from 'react';
import FacetContainer from './Components/FacetContainer/FacetContainer';
import AnimalContainer from './Components/AnimalContainer/AnimalContainer';
import axios from 'axios';
import config from './config'
import './App.css';
import _ from 'lodash';

class App extends Component {
  constructor(props) {
    super(props);
    this.endpoint = config.apiEndpoint;

    this.state = {
      animals: [],
      facets: {},
      selectedFacets: {},
      andFacets: [],
      andAbleFacets: ["options", "breeds"]
    };
  }

  onFacetChange(updatedFacets) {
    this.setState({
      selectedFacets: updatedFacets
    });
  }

  onAndFacetChange(updatedFacets) {
    this.setState({
      andFacets: updatedFacets
    });
  }

  componentDidMount() {
    this.loadAnimals().then(animals => {
      this.setState({
        animals: animals
      });
      this.loadFacets();
    })
  }

  loadAnimals() {
    return axios.get(this.endpoint)
      .then(response => {
        return response.data['pets'];
      });
  }

  loadFacets() {
    // let petType = this.createFacetEntriesForFacetName('petType');
    let breeds = this.createFacetEntriesForFacetName('breeds');
    let age = this.createFacetEntriesForFacetName('age');
    let size = this.createFacetEntriesForFacetName('size');
    let sex = this.createFacetEntriesForFacetName('sex');
    let options = this.createFacetEntriesForFacetName('options');

    this.setState({
      facets: { options, age, size, sex, breeds }
    });
  }

  createFacetEntriesForFacetName(facetName) {
    let animals = this.state.animals;
    let availableEntriesForFacet = _.flatMap(animals, animal => _.get(animal, facetName));
    return availableEntriesForFacet.reduce(function(map, obj) {
      map[obj] = false;
      return map;
    }, {});
  }

  render() {
    return (
      <div className="App">
        <div className="container-fluid app-container">
          <div className="row">
            <div className="Side-bar col-xs-4 col-md-3">
              <FacetContainer onFacetChange={this.onFacetChange.bind(this)}
                              onAndFacetChange={this.onAndFacetChange.bind(this)}
                              andFacets={this.state.andFacets}
                              andAbleFacets={this.state.andAbleFacets}
                              facets={this.state.facets}>
              </FacetContainer>
            </div>
            <div className="App-content col-xs-8 col-md-9">
              <AnimalContainer selectedFacets={this.state.selectedFacets}
                               andFacets={this.state.andFacets}
                               animals={this.state.animals}>
              </AnimalContainer>
            </div>
          </div>
        </div>
      </div>
    );
  }
}

export default App;
