export type property = string | number | boolean

export type properties = {
    audioID: string,
    destroyOnEnded: boolean?,
    [string]: property,
}

export type metadata = {[string]: property}

export type basicAudio = {
    properties: properties?,
    metadata: metadata?,
}

export type audio = basicAudio & {
    group: string,
    instance: Sound?,
    replicates: boolean,
}

export type queueAudio = basicAudio & {
    id: string,
}

export type queue = { queueAudio }

return nil
