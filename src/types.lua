export type audio = {
    instance: Sound,
    group: string,
    replicates: boolean,
}

export type property = string | number | boolean

export type properties = {
    audioID: string,
    destroyOnEnded: boolean?,
    [string]: property,
}

return nil