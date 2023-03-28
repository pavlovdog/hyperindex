import { NewGravatar, UpdatedGravatar } from "../generated/Gravatar/Gravatar";
import { Gravatar } from "../generated/schema";

let gravatarNewGravatarEventHandler = (event: NewGravatar, context) => {
  let gravatarObject = {
    id: event.params.id,
    owner: event.params.owner,
    displayName: event.params.displayName,
    imageUrl: event.params.imageUrl,
  };

  context.Gravatar.insert(gravatarObject);
};

let gravatarUpdatedGravatarEventHandler = (event: UpdatedGravatar, context) => {
  let gravatar = {
    id: event.params.id,
    owner: event.params.owner,
    displayName: event.params.displayName,
    imageUrl: event.params.imageUrl,
  };

  context.Gravatar.update(gravatar);
};
