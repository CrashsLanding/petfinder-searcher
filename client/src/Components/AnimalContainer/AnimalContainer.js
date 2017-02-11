import React from 'react';
import './AnimalContainer.css';
import Animal from '../Animal/Animal';
import _ from 'lodash';

class AnimalContainer extends React.Component {
  constructor(props) {
    super(props);

    this.state = {
      animals: {},
      andFacets: {}
    };
  }

  shouldDisplayAnimal(animal) {
    return _.every(_.map(this.props.selectedFacets, (facetArray, facetName)=> {
      if (_.isEmpty(facetArray)) return true;

      let animalFacetValue = _.get(animal, facetName);

      if (_.isArray(animalFacetValue)) {
        let andFacet = _.includes(this.props.andFacets, facetName);
        if (andFacet) {
          return _.intersection(facetArray, animalFacetValue).length >= facetArray.length;
        } else {
          return _.intersection(facetArray, animalFacetValue).length > 0;
        }
      } else {
        return _.includes(facetArray, animalFacetValue);
      }
    }));
  }

  getFilteredAnimals() {
    return _.filter(this.props.animals, animal => {
      return this.shouldDisplayAnimal(animal);
    })
  }

  render() {
    let animals = this.getFilteredAnimals();
    return <div className="AnimalContainer col-xs-12 col-sm-9">
      <div className="count">Found <strong>{animals.length}</strong> animals matching your search</div>
      {_.map(animals, (animal) => {
        return <Animal key={animal.id}
                       url={animal.petfinderUrl}
                       name={animal.name}
                       sex={animal.sex}
                       age={animal.age}
                       imageUrl={animal.photoUrl}
                       breeds={animal.breeds}>
        </Animal>
      })}
    </div>
  }
}

AnimalContainer.propTypes = {
  animals: React.PropTypes.array,
  selectedFacets: React.PropTypes.object,
  andFacets: React.PropTypes.array
}

export default AnimalContainer;
