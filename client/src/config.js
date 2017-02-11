export default {
  apiEndpoint: process.env.NODE_ENV === 'production' ? "/api/pets/all" : "http://localhost:4567/api/pets/all"
}
