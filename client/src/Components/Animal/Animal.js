import React from 'react';
import { Glyphicon } from 'react-bootstrap';
import './Animal.css';

function Animal(props) {
    return <div className="Animal flip-container col-xs-12 col-sm-6 col-md-4 col-xl-3">
      <div className="flipper">
        <a target="_blank" href={props.url}>
          <div className="front">
              <img src={props.imageUrl} alt={props.name} />
              <div className="animal-name"><span>{props.name}</span></div>
          </div>
          <div className="back">
            <div className="title">
              <h4>{props.name}</h4>
              <span>{props.sex}, {props.age}</span>
            </div>
            <ul className="breeds">
              {props.breeds.map((breed, i) => <li key={i}>{breed}</li>)}
            </ul>
            <div className="moreInfo">
              <p>More Info <Glyphicon glyph="chevron-right" /> </p>
            </div>
          </div>
        </a>
      </div>
    </div>
}

Animal.propTypes = {
  id: React.PropTypes.number,
  name: React.PropTypes.string,
  animal: React.PropTypes.string,
  mix: React.PropTypes.bool,
  age: React.PropTypes.string,
  shelterId: React.PropTypes.string,
  shelterPetId: React.PropTypes.string,
  sex: React.PropTypes.string,
  size: React.PropTypes.string,
  description: React.PropTypes.string,
  last_update: React.PropTypes.string,
  status: React.PropTypes.string,
  contact: React.PropTypes.string
}

export default Animal;
